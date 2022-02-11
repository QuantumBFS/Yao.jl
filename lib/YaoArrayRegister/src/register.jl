import BitBasis: BitStr, BitStr64

"""
    ArrayReg{B, D, T, MT <: AbstractMatrix{T}} <: AbstractRegister{B,D}

Simulated full amplitude register type, it uses an array to represent
corresponding one or a batch of quantum states. `B` is the batch size, `T`
is the numerical type for each amplitude, it is `ComplexF64` by default.
"""
mutable struct ArrayReg{B,D,T,MT<:AbstractMatrix{T}} <: AbstractRegister{B,D}
    state::MT
end

Adapt.@adapt_structure ArrayReg

const AdjointArrayReg{B,D,T,MT} = AdjointRegister{B,D,ArrayReg{B,D,T,MT}}
const ArrayRegOrAdjointArrayReg{B,D,T,MT} =
    Union{ArrayReg{B,D,T,MT},AdjointRegister{B,D,ArrayReg{B,D,T,MT}}}

"""
    ArrayReg{B}(raw; nlevel=2)
    ArrayReg{B,D}(raw)
    ArrayReg(raw::AbstractVecOrMat)

Construct an array register from a raw array. The size of batch should be declared
explicitly. The batch size will be `size(raw, 2)` by default.

!!! warning

    `ArrayReg` constructor will not normalize the quantum state. If you need a
    normalized quantum state remember to use `normalize!(register)` on the register or
    normalize the input raw array with `normalize` or [`batched_normalize!`](@ref).
"""
ArrayReg{B}(raw::AbstractMatrix; nlevel=2) where B = ArrayReg{B,nlevel}(raw)
function ArrayReg{B,D}(raw::MT) where {B,D,T,MT<:AbstractMatrix{T}}
    ispow(size(raw, 1), D) ||
        throw(DimensionMismatch("Expect first dimension size to be power of $D"))
    if !(ispow(size(raw, 2) ÷ B, D) && size(raw, 2) % B == 0)
        throw(
            DimensionMismatch(
                "Expect second dimension size to be an integral multiple of batch size $B",
            ),
        )
    end
    return ArrayReg{B,D,T,MT}(raw)
end

"""
    datatype(register) -> Int

Returns the numerical data type used by register.

!!! note

    `datatype` is not the same with `eltype`, since `AbstractRegister` family
    is not exactly the same with `AbstractArray`, it is an iterator of several
    registers.
"""
datatype(r::ArrayReg{B,D,T}) where {B,D,T} = T

function _warn_type(raw::AbstractArray{T}) where {T}
    T <: Complex || @warn "Input type of `ArrayReg` is not Complex, got $(eltype(raw))"
end

ArrayReg(raw::AbstractVector) = (_warn_type(raw); ArrayReg(reshape(raw, :, 1)))
ArrayReg(raw::AbstractMatrix) = (_warn_type(raw); ArrayReg{size(raw, 2)}(raw))
ArrayReg(raw::AbstractArray{<:Any,3}) =
    (_warn_type(raw); ArrayReg{size(raw, 3)}(reshape(raw, size(raw, 1), :)))

# bit literal
# NOTE: batch size B and element type T are 1 and ComplexF64 by default
"""
    ArrayReg([T=ComplexF64], bit_str)
    ArrayReg{B}([T=ComplexF64], bit_str)

Construct an array register from bit string literal. Batch size `B` is 1 by default.
For bit string literal please read [`@bit_str`](@ref).

# Examples

```jldoctest; setup=:(using YaoArrayRegister)
julia> ArrayReg(bit"1010")
ArrayReg{1, 2, ComplexF64, Array...}
    active qudits: 4/4

julia> ArrayReg(ComplexF32, bit"1010")
ArrayReg{1, 2, ComplexF32, Array...}
    active qudits: 4/4
```
"""
ArrayReg(bitstr::BitStr) = ArrayReg(ComplexF64, bitstr)
ArrayReg(::Type{T}, bitstr::BitStr) where {T} = ArrayReg{1}(T, bitstr)
ArrayReg{B}(bitstr::BitStr) where {B} = ArrayReg{B}(ComplexF64, bitstr)
ArrayReg{B}(::Type{T}, bitstr::BitStr) where {B,T} = ArrayReg{B}(onehot(T, bitstr, B))


"""
    ArrayReg(r::ArrayReg)

Initialize a new `ArrayReg` by an existing `ArrayReg`. This is equivalent
to `copy`.
"""
ArrayReg(r::ArrayReg{B,D}) where {B,D} = ArrayReg{B,D}(copy(r.state))
ArrayReg(r::ArrayReg{B,D,T,<:Transpose}) where {B,D,T} =
    ArrayReg{B,D}(Transpose(copy(r.state.parent)))

transpose_storage(reg::ArrayReg{B,D,T,<:Transpose}) where {B,D,T} = ArrayReg{B,D}(copy(reg.state))
transpose_storage(reg::ArrayReg{B,D,T}) where {B,D,T} =
    ArrayReg{B,D}(transpose(copy(transpose(reg.state))))

Base.copy(r::ArrayReg) = ArrayReg(r)
Base.similar(r::ArrayRegOrAdjointArrayReg{B,D}) where {B,D} = ArrayReg{B,D}(similar(state(r)))

# NOTE: ket bra is not copyable
function Base.copyto!(dst::ArrayReg, src::ArrayReg)
    copyto!(state(dst), state(src))
    return dst
end

function Base.copyto!(dst::AdjointArrayReg, src::AdjointArrayReg)
    copyto!(state(dst), state(src))
    return dst
end

# register interface
YaoBase.nqubits(r::ArrayReg{B,2}) where {B} = log2i(length(r.state) ÷ B)
YaoBase.nqudits(r::ArrayReg{B,D}) where {B,D} = logdi(length(r.state) ÷ B, D)
YaoBase.nactive(r::ArrayReg) = log2dim1(r.state)
YaoBase.viewbatch(r::ArrayReg, ind::Int) = @inbounds ArrayReg{1}(view(rank3(r), :, :, ind))

function YaoBase.addbits!(r::ArrayReg{B,D}, n::Int) where {B,D}
    raw = state(r)
    M, N = size(raw)
    r.state = similar(r.state, M * (D ^ n), N)
    fill!(r.state, 0)
    r.state[1:M, :] = raw
    return r
end

function YaoBase.insert_qudits!(reg::ArrayReg{B}, loc::Int; nqudits::Int = 1) where {B}
    na = nactive(reg)
    focus!(reg, 1:loc-1)
    reg2 = join(zero_state(nqudits; nbatch = B), reg) |> relax! |> focus!((1:na+nqudits)...)
    reg.state = reg2.state
    reg
end

function YaoBase.probs(r::ArrayReg{1})
    if size(r.state, 2) == 1
        return vec(r.state .|> abs2)
    else
        return dropdims(sum(r.state .|> abs2, dims = 2), dims = 2)
    end
end

function YaoBase.probs(r::ArrayReg{B}) where {B}
    if size(r.state, 2) == B
        return r.state .|> abs2
    else
        probs = r |> rank3 .|> abs2
        return dropdims(sum(probs, dims = 2), dims = 2)
    end
end

function YaoBase.reorder!(r::ArrayReg, orders)
    @inbounds for i = 1:size(r.state, 2)
        r.state[:, i] = reorder(r.state[:, i], orders)
    end
    return r
end

function YaoBase.collapseto!(r::ArrayReg, bit_config::Integer)
    st = normalize!(r.state[Int(bit_config)+1, :])
    fill!(r.state, 0)
    r.state[Int(bit_config)+1, :] .= st
    return r
end

"""
    fidelity(r1::ArrayReg, r2::ArrayReg)

Calcuate the fidelity between `r1` and `r2`, if `r1` or `r2` is not pure state
(`nactive(r) != nqudits(r)`), the fidelity is calcuated by purification. See also
[`pure_state_fidelity`](@ref), [`purification_fidelity`](@ref).


    fidelity'(pair_or_reg1, pair_or_reg2) -> (g1, g2)

Obtain the gradient with respect to registers and circuit parameters.
For pair input `ψ=>circuit`, the returned gradient is a pair of `gψ=>gparams`,
with `gψ` the gradient of input state and `gparams` the gradients of circuit parameters.
For register input, the return value is a register.
"""
function YaoBase.fidelity(r1::ArrayReg{B1}, r2::ArrayReg{B2}) where {B1,B2}
    B1 == B2 || throw(DimensionMismatch("Register batch not match!"))
    B = B1

    state1 = rank3(r1)
    state2 = rank3(r2)
    size(state1) == size(state2) || throw(DimensionMismatch("Register size not match!"))
    if size(state1, 2) == 1
        res = map(b -> pure_state_fidelity(state1[:, 1, b], state2[:, 1, b]), 1:B)
    else
        res = map(b -> purification_fidelity(state1[:, :, b], state2[:, :, b]), 1:B)
    end
    return B == 1 ? res[] : res
end

function YaoBase.fidelity(r1::ArrayReg{B}, r2::ArrayReg{1}) where {B}
    state1 = rank3(r1)
    state2 = rank3(r2)
    nqudits(r1) == nqudits(r2) || throw(DimensionMismatch("Register size not match!"))
    if size(state1, 2) == 1
        res = map(b -> pure_state_fidelity(state1[:, 1, b], state2[:, 1, 1]), 1:B)
    else
        res = map(b -> purification_fidelity(state1[:, :, b], state2[:, :, 1]), 1:B)
    end
    return B == 1 ? res[] : res
end

YaoBase.fidelity(r1::ArrayReg{1}, r2::ArrayReg{B}) where {B} = YaoBase.fidelity(r2, r1)

function YaoBase.fidelity(r1::ArrayReg{1}, r2::ArrayReg{1})
    state1 = state(r1)
    state2 = state(r2)
    nqudits(r1) == nqudits(r2) || throw(DimensionMismatch("Register size not match!"))

    if size(state1, 2) == 1
        return pure_state_fidelity(state1[:, 1], state2[:, 1])
    else
        return purification_fidelity(state1, state2)
    end
end

YaoBase.tracedist(r1::ArrayReg{B}, r2::ArrayReg{B}) where {B} = tracedist(ρ(r1), ρ(r2))


# properties
"""
    state(register::ArrayReg) -> raw array

Returns the raw array storage of `register`. See also [`statevec`](@ref).
"""
state(r::ArrayReg) = r.state
state(r::AdjointArrayReg) = adjoint(state(parent(r)))

"""
    statevec(r::ArrayReg) -> array

Return a state matrix/vector by droping the last dimension of size 1. See also [`state`](@ref).

!!! warning
    `statevec` is not type stable. It may cause performance slow down.
"""
statevec(r::ArrayRegOrAdjointArrayReg) = matvec(state(r))

"""
    relaxedvec(r::ArrayReg) -> AbstractArray

Return a matrix (vector) for B>1 (B=1) as a vector representation of state, with all qudits activated.
See also [`state`](@ref), [`statevec`](@ref).
"""
relaxedvec(r::ArrayReg{B}) where {B} = reshape(state(r), :, B)
relaxedvec(r::ArrayReg{1}) = vec(state(r))

"""
    hypercubic(r::ArrayReg) -> AbstractArray

Return the hypercubic form (high dimensional tensor) of this register, only active qudits are considered.
See also [`rank3`](@ref).
"""
BitBasis.hypercubic(r::ArrayRegOrAdjointArrayReg) =
    reshape(state(r), ntuple(i -> 2, Val(nactive(r)))..., :)

"""
    rank3(r::ArrayReg)

Return the rank 3 tensor representation of state,
the 3 dimensions are (activated space, remaining space, batch dimension).
See also [`rank3`](@ref).
"""
rank3(r::ArrayRegOrAdjointArrayReg{B}) where {B} =
    reshape(state(r), size(state(r), 1), :, B)

"""
    join(regs...)

concat a list of registers `regs` to a larger register, each register should
have the same batch size. See also [`repeat`](@ref).
"""
Base.join(rs::ArrayReg{B}...) where {B} = _join(join_datatype(rs...), rs...)
Base.join(r::ArrayReg) = r

function _join(::Type{T}, rs::ArrayReg{B}...) where {T,B}
    state = batched_kron(rank3.(rs)...)
    return ArrayReg{B}(reshape(state, size(state, 1), :))
end

join_datatype(r::ArrayReg{B,D,T}, rs::ArrayReg{B,D,T}...) where {B,D,T} = join_datatype(T, r, rs...)
join_datatype(::Type{T}, r::ArrayReg{B,D,T1}, rs::ArrayReg{B}...) where {T,T1,B,D} =
    join_datatype(promote_type(T, T1), rs...)
join_datatype(::Type{T}) where {T} = T


# initialization methods
"""
    product_state([T=ComplexF64], bit_str; nbatch=1)

Create an [`ArrayReg`](@ref) with bit string literal
defined with [`@bit_str`](@ref). See also [`zero_state`](@ref),
[`rand_state`](@ref), [`uniform_state`](@ref).

# Examples

```jldoctest; setup=:(using YaoArrayRegister)
julia> product_state(bit"100"; nbatch=2)
ArrayReg{2, 2, ComplexF64, Transpose...}
    active qudits: 3/3

julia> r1 = product_state(ComplexF32, bit"100"; nbatch=2)
ArrayReg{2, 2, ComplexF32, Transpose...}
    active qudits: 3/3

julia> r2 = product_state(ComplexF32, [0, 0, 1]; nbatch=2)
ArrayReg{2, 2, ComplexF32, Transpose...}
    active qudits: 3/3

julia> r1 ≈ r2   # because we read bit strings from right to left, vectors from left to right.
true
```
"""
product_state(bit_str::BitStr; nbatch::Int = 1) =
    product_state(ComplexF64, bit_str; nbatch = nbatch)

product_state(bit_str::AbstractVector; nbatch::Int = 1) =
    product_state(ComplexF64, bit_str; nbatch = nbatch)

"""
    product_state([T=ComplexF64], total::Int, bit_config::Integer; nbatch=1, no_transpose_storage=false)

Create an [`ArrayReg`](@ref) with bit configuration `bit_config`, total number of bits `total`.
See also [`zero_state`](@ref), [`rand_state`](@ref), [`uniform_state`](@ref).

# Examples

```jldoctest; setup=:(using YaoArrayRegister)
julia> product_state(4, 3; nbatch=2)
ArrayReg{2, 2, ComplexF64, Transpose...}
    active qudits: 4/4

julia> product_state(4, 0b1001; nbatch=2)
ArrayReg{2, 2, ComplexF64, Transpose...}
    active qudits: 4/4

julia> product_state(ComplexF32, 4, 0b101)
ArrayReg{1, 2, ComplexF32, Array...}
    active qudits: 4/4
```

!!! warning

    This interface will not check whether the number of required digits
    for the bit configuration matches the total number of bits.
"""
product_state(total::Int, bit_config::Integer; kwargs...) =
    product_state(ComplexF64, total, bit_config; kwargs...)

product_state(::Type{T}, bit_str::BitStr{N}; kwargs...) where {T,N} =
    product_state(T, N, buffer(bit_str); kwargs...)

product_state(::Type{T}, bit_configs::AbstractVector; kwargs...) where {T} =
    product_state(T, bit_literal(bit_configs...); kwargs...)

function product_state(
    ::Type{T},
    total::Int,
    bit_config::Integer;
    nbatch::Int = 1,
    no_transpose_storage::Bool = false,
) where {T}
    if nbatch == 1 || no_transpose_storage
        raw = onehot(T, total, bit_config, nbatch)
    else
        raw = zeros(T, nbatch, 1 << total)
        raw[:, Int(bit_config)+1] .= 1
        raw = transpose(raw)
    end
    return ArrayReg{nbatch}(raw)
end

"""
    zero_state([T=ComplexF64], n::Int; nbatch::Int=1)

Create an [`ArrayReg`](@ref) with total number of bits `n`.
See also [`product_state`](@ref), [`rand_state`](@ref), [`uniform_state`](@ref).

# Examples

```jldoctest; setup=:(using YaoArrayRegister)
julia> zero_state(4)
ArrayReg{1, 2, ComplexF64, Array...}
    active qudits: 4/4

julia> zero_state(ComplexF32, 4)
ArrayReg{1, 2, ComplexF32, Array...}
    active qudits: 4/4

julia> zero_state(ComplexF32, 4; nbatch=3)
ArrayReg{3, 2, ComplexF32, Transpose...}
    active qudits: 4/4
```
"""
zero_state(n::Int; kwargs...) = zero_state(ComplexF64, n; kwargs...)
zero_state(::Type{T}, n::Int; kwargs...) where {T} = product_state(T, n, 0; kwargs...)


"""
    rand_state([T=ComplexF64], n::Int; nbatch=1, no_transpose_storage=false)

Create a random [`ArrayReg`](@ref) with total number of qudits `n`.

# Examples

```jldoctest; setup=:(using YaoArrayRegister)
julia> rand_state(4)
ArrayReg{1, 2, ComplexF64, Array...}
    active qudits: 4/4

julia> rand_state(ComplexF64, 4)
ArrayReg{1, 2, ComplexF64, Array...}
    active qudits: 4/4

julia> rand_state(ComplexF64, 4; nbatch=2)
ArrayReg{2, 2, ComplexF64, Transpose...}
    active qudits: 4/4
```
"""
rand_state(n::Int; kwargs...) = rand_state(ComplexF64, n; kwargs...)

function rand_state(
    ::Type{T},
    n::Int;
    nbatch::Int = 1,
    no_transpose_storage::Bool = false,
    nlevel = 2,
) where {T}
    raw =
        nbatch == 1 || no_transpose_storage ? randn(T, nlevel ^ n, nbatch) :
        transpose(randn(T, nbatch, nlevel ^ n))
    return normalize!(ArrayReg{nbatch, nlevel}(raw))
end

"""
    uniform_state([T=ComplexF64], n; nbatch=1, no_transpose_storage=false)

Create a uniform state: ``\\frac{1}{2^n} \\sum_k |k⟩``. This state
can also be created by applying [`H`](@ref) (Hadmard gate) on ``|00⋯00⟩`` state.

# Example

```jldoctest; setup=:(using YaoArrayRegister)
julia> uniform_state(4; nbatch=2)
ArrayReg{2, 2, ComplexF64, Transpose...}
    active qudits: 4/4

julia> uniform_state(ComplexF32, 4; nbatch=2)
ArrayReg{2, 2, ComplexF32, Transpose...}
    active qudits: 4/4
```
"""
uniform_state(n::Int; kwargs...) = uniform_state(ComplexF64, n; kwargs...)
function uniform_state(
    ::Type{T},
    n::Int;
    nbatch::Int = 1,
    nlevel::Int = 2,
    no_transpose_storage::Bool = false,
) where {T}
    raw =
        nbatch == 1 || no_transpose_storage ? ones(T, nlevel ^ n, nbatch) :
        transpose(ones(T, nbatch, nlevel ^ n))
    normalize!(ArrayReg{nbatch, nlevel}(raw))
end

"""
    oneto(r::ArrayReg, n::Int=nqudits(r))

Returns an `ArrayReg` with `1:n` qudits activated.
"""
oneto(r::ArrayReg{B,D}, n::Int = nqudits(r)) where {B,D} =
    ArrayReg{B,D}(reshape(copy(r.state), D ^ n, :))
oneto(r::ArrayReg{B,D,T,<:Transpose}, n::Int = nqudits(r)) where {B,D,T} =
    transpose_storage(ArrayReg{B}(reshape(r.state, D ^ n, :)))

"""
    oneto(n::Int) -> f(register)

Like `oneto(register, n)`, but the input `register` is delayed.
"""
oneto(n::Int) = r -> oneto(r, n)

"""
    repeat(register, n)

Create an [`ArrayReg`](@ref) by copying the original `register` for `n` times on
batch dimension.

# Example

```jldoctest; setup=:(using YaoArrayRegister)
julia> repeat(ArrayReg{3}(bit"101"), 4)
ArrayReg{12, 2, ComplexF64, Array...}
    active qudits: 3/3
```
"""
Base.repeat(r::ArrayReg{B}, n::Int) where {B} =
    ArrayReg{B * n}(hcat((state(r) for k = 1:n)...))

# NOTE: overload this to make printing more compact
#       but do not alter the way how type parameters print
function Base.summary(io::IO, r::ArrayReg{B,D,T,MT}) where {B,D,T,MT}
    print(io, "ArrayReg{$B, $D, $T, $(nameof(MT))...}")
end

"""
    mutual_information(reg::ArrayReg, part1, part2)

Compute the mutual information between locations `part1` and locations `part2` in a quantum state `reg`.
"""
function mutual_information(reg::ArrayReg, part1, part2)
    von_neumann_entropy(reg, part1) + von_neumann_entropy(reg, part2) - von_neumann_entropy(reg, part1 ∪ part2)
end

"""
    von_neumann_entropy(reg::AbstractRegister, part)
    von_neumann_entropy(ρ::DensityMatrix)

The entanglement entropy between `part` and the rest part in quantum state `reg`.
If the input is a density matrix, it returns the entropy of a mixed state.
"""
function von_neumann_entropy(reg::AbstractRegister, part)
    reg2 = focus!(copy(reg), part)
    von_neumann_entropy(density_matrix(reg2))
end
