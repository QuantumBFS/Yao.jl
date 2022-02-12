import BitBasis: BitStr, BitStr64

abstract type AbstractArrayReg{D,T,AT} <: AbstractRegister{D} end

struct NoBatch end
_asint(x::Int) = x
_asint(::NoBatch) = 1


"""
    ArrayReg{D,T,MT<:AbstractMatrix{T}} <: AbstractArrayRegister{D}
    ArrayReg{D}(raw)
    ArrayReg(raw::AbstractVecOrMat; nlevel=2)
    ArrayReg(r::ArrayReg)

Simulated full amplitude register type, it uses an array to represent
corresponding one or a batch of quantum states. `T`
is the numerical type for each amplitude, it is `ComplexF64` by default.

!!! warning

    `ArrayReg` constructor will not normalize the quantum state. If you need a
    normalized quantum state remember to use `normalize!(register)` on the register or
    normalize the input raw array with `normalize` or [`batched_normalize!`](@ref).
"""
mutable struct ArrayReg{D,T,MT<:AbstractMatrix{T}} <: AbstractArrayReg{D,T,MT}
    state::MT
    function ArrayReg{D,T,MT}(state::MT) where {D,T, MT<:AbstractMatrix{T}}
        _check_reg_input(state, D, 1)
        return new{D,T,MT}(state)
    end
end

ArrayReg(raw; nlevel=2) = ArrayReg{nlevel}(raw)
ArrayReg{D}(raw::AbstractVector) where D = ArrayReg{D}(reshape(raw, :, 1))
function ArrayReg{D}(raw::MT) where {D,T,MT<:AbstractMatrix{T}}
    return ArrayReg{D,T,MT}(raw)
end

ArrayReg(r::ArrayReg{D}) where {D} = ArrayReg{D}(copy(r.state))
ArrayReg(r::ArrayReg{D,T,<:Transpose}) where {D,T} =
        ArrayReg{D}(Transpose(copy(r.state.parent)))

Base.copy(r::ArrayReg) = ArrayReg(r)
Base.similar(r::ArrayReg{D}) where D = ArrayReg{D}(similar(state(r)))
Base.similar(r::ArrayReg{D}, state::AbstractMatrix) where D = ArrayReg{D}(state)

"""
    BatchedArrayReg{D,T,MT<:AbstractMatrix{T}} <: AbstractArrayReg{D}
    BatchedArrayReg(raw, nbatch; nlevel=2)
    BatchedArrayReg{D}(raw, nbatch)

Simulated batched full amplitude register type, it uses an array to represent
corresponding one or a batch of quantum states. `T`
is the numerical type for each amplitude, it is `ComplexF64` by default.

!!! warning

    `BatchedArrayReg` constructor will not normalize the quantum state. If you need a
    normalized quantum state remember to use `normalize!(register)` on the register or
    normalize the input raw array with `normalize` or [`batched_normalize!`](@ref).
"""
mutable struct BatchedArrayReg{D,T,MT<:AbstractMatrix{T}} <: AbstractArrayReg{D,T,MT}
    state::MT
    nbatch::Int
    function BatchedArrayReg{D,T,MT}(state::MT, nbatch::Int) where {D,T, MT<:AbstractMatrix{T}}
        _check_reg_input(state, D, nbatch)
        return new{D,T,MT}(state, nbatch)
    end
end
BatchedArrayReg(raw::AbstractMatrix, nbatch::Int=size(raw, 2); nlevel=2) = BatchedArrayReg{nlevel}(raw, nbatch)
function BatchedArrayReg{D}(raw::MT, nbatch::Int) where {D,T,MT<:AbstractMatrix{T}}
    return BatchedArrayReg{D,T,MT}(raw, nbatch)
end

BatchedArrayReg(r::BatchedArrayReg{D}) where {D} = BatchedArrayReg{D}(copy(r.state), r.nbatch)
BatchedArrayReg(r::BatchedArrayReg{D,T,<:Transpose}) where {D,T} =
        BatchedArrayReg{D}(Transpose(copy(r.state.parent)), r.nbatch)

Base.copy(r::BatchedArrayReg) = BatchedArrayReg(r)
Base.similar(r::BatchedArrayReg{D}) where D = BatchedArrayReg{D}(similar(state(r)), r.nbatch)
Base.similar(r::BatchedArrayReg{D}, state::AbstractMatrix) where D = BatchedArrayReg{D}(state, r.nbatch)
YaoBase.viewbatch(r::ArrayReg, ind::Int) = ind == 1 ? r : error("Index `$ind` out of bounds, should be `1`.")

# convert
function ArrayReg(r::BatchedArrayReg{D}) where D
    if nbatch(r) != 1
        error("can not convert a `BatchedArrayReg` with `nbatch != 1` to a `ArrayReg`")
    else
        return ArrayReg{D}(r.state)
    end
end
BatchedArrayReg(r::ArrayReg{D}...) where D = BatchedArrayReg{D}(hcat(state.(r)...), length(r))

function _check_reg_input(raw::AbstractMatrix{T}, D::Integer, B::Integer) where T
    _warn_type(raw)
    if D <= 0
        error("invalid number of level: $D")
    end
    if B < 0
        error("invalid batch size: $B")
    end
    ispow(size(raw, 1), D) ||
        throw(DimensionMismatch("Expect first dimension size to be power of $D"))
    if !(ispow(size(raw, 2) ÷ B, D) && size(raw, 2) % B == 0)
        throw(
            DimensionMismatch(
                "Expect second dimension size to be an integer multiple of batch size $B",
            ),
        )
    end
end

function _warn_type(raw::T) where T
    T <: Complex || @warn "Input matrix element type is not `Complex`, got `$(eltype(raw))`"
end

"""
    arrayreg(state; nbatch::Union{Integer,NoBatch}=NoBatch(), nlevel::Integer=2)

Create an array register, if nbatch is a integer, it will return a `BatchedArrayReg`.
"""
function arrayreg(state; nbatch::Union{Integer,NoBatch}=NoBatch(), nlevel::Integer=2)
    if nbatch isa NoBatch
        return ArrayReg{nlevel}(state)
    else
        return BatchedArrayReg{nlevel}(state, nbatch)
    end
end

Adapt.@adapt_structure ArrayReg
Adapt.@adapt_structure BatchedArrayReg

const AdjointArrayReg{D,T,MT} = AdjointRegister{D,<:AbstractArrayReg{D,T,MT}}
const ArrayRegOrAdjointArrayReg{D,T,MT} =
    Union{AbstractArrayReg{D,T,MT},AdjointArrayReg{D,T,MT}}

"""
    datatype(register) -> Int

Returns the numerical data type used by register.

!!! note

    `datatype` is not the same with `eltype`, since `AbstractRegister` family
    is not exactly the same with `AbstractArray`, it is an iterator of several
    registers.
"""
datatype(r::AbstractArrayReg{D,T}) where {D,T} = T

"""
    arrayreg([T=ComplexF64], bit_str; nbatch=NoBatch())

Construct an array register from bit string literal.
For bit string literal please read [`@bit_str`](@ref).

# Examples

```jldoctest; setup=:(using YaoArrayRegister)
julia> arrayreg(bit"1010")
ArrayReg{1, 2, ComplexF64, Array...}
    active qudits: 4/4

julia> arrayreg(ComplexF32, bit"1010")
ArrayReg{1, 2, ComplexF32, Array...}
    active qudits: 4/4
```
"""
arrayreg(bitstr::BitStr; nbatch::Union{Int,NoBatch}=NoBatch()) = arrayreg(ComplexF64, bitstr; nbatch=nbatch)
arrayreg(::Type{T}, bitstr::BitStr; nbatch::Union{Int,NoBatch}=NoBatch()) where {T} = arrayreg(onehot(T, bitstr, _asint(nbatch)); nbatch=nbatch, nlevel=2)

transpose_storage(reg::AbstractArrayReg{D,T,<:Transpose}) where {D,T} = arrayreg(copy(reg.state); nbatch=nbatch(reg), nlevel=D)
transpose_storage(reg::AbstractArrayReg) =
    arrayreg(transpose(copy(transpose(reg.state))); nbatch=nbatch(reg), nlevel=nlevel(reg))

# NOTE: ket bra is not copyable
function Base.copyto!(dst::AbstractArrayReg, src::AbstractArrayReg)
    copyto!(state(dst), state(src))
    return dst
end

function Base.copyto!(dst::AdjointArrayReg, src::AdjointArrayReg)
    copyto!(state(dst), state(src))
    return dst
end

# register interface
YaoBase.nqudits(r::AbstractArrayReg{2}) = log2i(length(r.state) ÷ _asint(nbatch(r)))
YaoBase.nqudits(r::AbstractArrayReg{D}) where {D} = logdi(length(r.state) ÷ _asint(nbatch(r)), D)
YaoBase.nactive(r::AbstractArrayReg{D}) where {D} = logdi(size(r.state, 1), D)
YaoBase.viewbatch(r::BatchedArrayReg{D}, ind::Int) where D = @inbounds ArrayReg{D}(view(rank3(r), :, :, ind))

function YaoBase.addbits!(r::AbstractArrayReg{D}, n::Int) where {D}
    raw = state(r)
    M, N = size(raw)
    r.state = similar(r.state, M * (D ^ n), N)
    fill!(r.state, 0)
    r.state[1:M, :] = raw
    return r
end

function YaoBase.insert_qudits!(reg::AbstractArrayReg{D}, loc::Int; nqudits::Int = 1) where D
    na = nactive(reg)
    focus!(reg, 1:loc-1)
    reg2 = join(zero_state(nqudits; nbatch = nbatch(reg), nlevel=D), reg) |> relax! |> focus!((1:na+nqudits)...)
    reg.state = reg2.state
    reg
end

function YaoBase.probs(r::ArrayReg)
    if size(r.state, 2) == 1
        return vec(r.state .|> abs2)
    else
        return dropdims(sum(r.state .|> abs2, dims = 2), dims = 2)
    end
end

function YaoBase.probs(r::BatchedArrayReg)
    if size(r.state, 2) == nbatch(r)
        return r.state .|> abs2
    else
        probs = r |> rank3 .|> abs2
        return dropdims(sum(probs, dims = 2), dims = 2)
    end
end

function YaoBase.reorder!(r::AbstractArrayReg, orders)
    @inbounds for i = 1:size(r.state, 2)
        r.state[:, i] = reorder(r.state[:, i], orders)
    end
    return r
end

function YaoBase.collapseto!(r::AbstractArrayReg, bit_config::Integer)
    st = normalize!(r.state[Int(bit_config)+1, :])
    fill!(r.state, 0)
    r.state[Int(bit_config)+1, :] .= st
    return r
end

"""
    fidelity(r1::AbstractArrayReg, r2::AbstractArrayReg)

Calcuate the fidelity between `r1` and `r2`, if `r1` or `r2` is not pure state
(`nactive(r) != nqudits(r)`), the fidelity is calcuated by purification. See also
[`pure_state_fidelity`](@ref), [`purification_fidelity`](@ref).


    fidelity'(pair_or_reg1, pair_or_reg2) -> (g1, g2)

Obtain the gradient with respect to registers and circuit parameters.
For pair input `ψ=>circuit`, the returned gradient is a pair of `gψ=>gparams`,
with `gψ` the gradient of input state and `gparams` the gradients of circuit parameters.
For register input, the return value is a register.
"""
function YaoBase.fidelity(r1::BatchedArrayReg{D}, r2::BatchedArrayReg{D}) where {D}
    B1, B2 = nbatch(r1), nbatch(r2)
    B1 == B2 || throw(DimensionMismatch("Register batch not match!"))
    B = nbatch(r1)

    state1 = rank3(r1)
    state2 = rank3(r2)
    size(state1) == size(state2) || throw(DimensionMismatch("Register size not match!"))
    if size(state1, 2) == 1
        res = map(b -> pure_state_fidelity(state1[:, 1, b], state2[:, 1, b]), 1:B)
    else
        res = map(b -> purification_fidelity(state1[:, :, b], state2[:, :, b]), 1:B)
    end
    return res
end

function YaoBase.fidelity(r1::BatchedArrayReg, r2::ArrayReg)
    B = nbatch(r1)
    state1 = rank3(r1)
    state2 = rank3(r2)
    nqudits(r1) == nqudits(r2) || throw(DimensionMismatch("Register size not match!"))
    if size(state1, 2) == 1
        res = map(b -> pure_state_fidelity(state1[:, 1, b], state2[:, 1, 1]), 1:B)
    else
        res = map(b -> purification_fidelity(state1[:, :, b], state2[:, :, 1]), 1:B)
    end
    return res
end

YaoBase.fidelity(r1::ArrayReg, r2::BatchedArrayReg) = YaoBase.fidelity(r2, r1)

function YaoBase.fidelity(r1::ArrayReg, r2::ArrayReg)
    state1 = state(r1)
    state2 = state(r2)
    nqudits(r1) == nqudits(r2) || throw(DimensionMismatch("Register size not match!"))

    if size(state1, 2) == 1
        return pure_state_fidelity(state1[:, 1], state2[:, 1])
    else
        return purification_fidelity(state1, state2)
    end
end

YaoBase.tracedist(r1::ArrayReg, r2::ArrayReg) = tracedist(ρ(r1), ρ(r2))
YaoBase.tracedist(r1::BatchedArrayReg, r2::BatchedArrayReg) = tracedist.(r1, r2)


# properties
"""
    state(register::AbstractArrayReg) -> raw array

Returns the raw array storage of `register`. See also [`statevec`](@ref).
"""
state(r::AbstractArrayReg) = r.state
state(r::AdjointArrayReg) = adjoint(state(parent(r)))

"""
    statevec(r::ArrayReg) -> array

Return a state matrix/vector by droping the last dimension of size 1. See also [`state`](@ref).

!!! warning
    `statevec` is not type stable. It may cause performance slow down.
"""
statevec(r::ArrayRegOrAdjointArrayReg) = matvec(state(r))

"""
    relaxedvec(r::AbstractArrayReg) -> AbstractArray

Return a vector representation of state, with all qudits activated.
See also [`state`](@ref), [`statevec`](@ref).
"""
relaxedvec(r::ArrayReg) = vec(state(r))
relaxedvec(r::BatchedArrayReg) = reshape(state(r), :, nbatch(r))

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
function rank3(r::ArrayRegOrAdjointArrayReg)
    s = state(r)
    reshape(s, size(s, 1), :, _asint(nbatch(r)))
end

"""
    join(regs...)

concat a list of registers `regs` to a larger register, each register should
have the same batch size. See also [`repeat`](@ref).
"""
Base.join(rs::AbstractArrayReg...) = _join(join_datatype(rs...), rs...)
Base.join(r::AbstractArrayReg) = r
function _join(::Type{T}, rs0::AbstractArrayReg{D}, rs::AbstractArrayReg{D}...) where {T,D}
    state = batched_kron(rank3(rs0), rank3.(rs)...)
    return arrayreg(reshape(state, size(state, 1), :), nbatch=nbatch(rs[1]), nlevel=D)
end

join_datatype(r::AbstractArrayReg{D,T}, rs::AbstractArrayReg{D,T}...) where {D,T} = join_datatype(T, r, rs...)
join_datatype(::Type{T}, r::AbstractArrayReg{D,T1}, rs::AbstractArrayReg...) where {T,T1,D} =
    join_datatype(promote_type(T, T1), rs...)
join_datatype(::Type{T}) where {T} = T


# initialization methods
"""
    product_state([T=ComplexF64], bit_str; nbatch=NoBatch())

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
product_state(bit_str::BitStr; nbatch::Union{NoBatch,Int} = NoBatch()) =
    product_state(ComplexF64, bit_str; nbatch = nbatch)

product_state(bit_str::AbstractVector; nbatch::Union{NoBatch,Int} = NoBatch()) =
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
    nbatch::Union{Int,NoBatch} = NoBatch(),
    nlevel::Int=2,
    no_transpose_storage::Bool = false,
) where {T}
    if nbatch isa NoBatch || no_transpose_storage
        raw = onehot(T, total, bit_config, _asint(nbatch))
    else
        raw = zeros(T, _asint(nbatch), nlevel ^ total)
        raw[:, Int(bit_config)+1] .= 1
        raw = transpose(raw)
    end
    return arrayreg(raw; nbatch=nbatch, nlevel=nlevel)
end

"""
    zero_state([T=ComplexF64], n::Int; nbatch::Int=1)

Create an [`AbstractArrayReg`](@ref) with total number of bits `n`.
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

Create a random [`AbstractArrayReg`](@ref) with total number of qudits `n`.

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
    nbatch::Union{Int,NoBatch} = NoBatch(),
    no_transpose_storage::Bool = false,
    nlevel = 2,
) where {T}
    raw =
        nbatch isa NoBatch || no_transpose_storage ? randn(T, nlevel ^ n, _asint(nbatch)) :
        transpose(randn(T, _asint(nbatch), nlevel ^ n))
    return normalize!(arrayreg(raw; nbatch=nbatch, nlevel=nlevel))
end

"""
    uniform_state([T=ComplexF64], n; nbatch=1, no_transpose_storage=false)

Create a uniform state: ``\\frac{1}{2^n} \\sum_k |k⟩``. This state
can also be created by applying [`H`](@ref) (Hadmard gate) on ``|00⋯00⟩`` state.

# Example

```jldoctest; setup=:(using YaoArrayRegister)
julia> uniform_state(4; nbatch=2)
BatchedArrayReg{2, 2, ComplexF64, Transpose...}
    active qudits: 4/4

julia> uniform_state(ComplexF32, 4; nbatch=2)
ArrayReg{2, 2, ComplexF32, Transpose...}
    active qudits: 4/4
```
"""
uniform_state(n::Int; kwargs...) = uniform_state(ComplexF64, n; kwargs...)

function uniform_state(::Type{T}, n::Int;
    nbatch::Union{Int,NoBatch} = NoBatch(),
    nlevel::Int = 2,
    no_transpose_storage::Bool = false,
) where {T}
    if (nbatch isa NoBatch) || no_transpose_storage
        raw = ones(T, nlevel ^ n, _asint(nbatch))
    else
        raw = transpose(ones(T, _asint(nbatch), nlevel ^ n))
    end
    return normalize!(arrayreg(raw; nbatch=nbatch, nlevel=nlevel))
end

"""
    oneto(n::Int) -> f(register)
    oneto(r::AbstractArrayReg, n::Int=nqudits(r))

Returns an register with `1:n` qudits activated.
"""
oneto(n::Int) = r -> oneto(r, n)
oneto(r::AbstractArrayReg{D}, n::Int = nqudits(r)) where {D} =
    arrayreg(reshape(copy(r.state), D ^ n, :), nbatch=nbatch(r), nlevel=D)
oneto(r::AbstractArrayReg{D,T,<:Transpose}, n::Int = nqudits(r)) where {D,T} =
    transpose_storage(arrayreg(reshape(r.state, D ^ n, :); nbatch=nbatch(r), nlevel=D))

"""
    repeat(register, n)

Create an [`ArrayReg`](@ref) by copying the original `register` for `n` times on
batch dimension.

# Example

```jldoctest; setup=:(using YaoArrayRegister)
julia> repeat(BatchedArrayReg(bit"101", 3), 4)
BatchedArrayReg{12, 2, ComplexF64, Array...}
    active qudits: 3/3
```
"""
Base.repeat(r::AbstractArrayReg{D}, n::Int) where D =
    BatchedArrayReg{D}(hcat((state(r) for k = 1:n)...), n * _asint(nbatch(r)))

# NOTE: overload this to make printing more compact
#       but do not alter the way how type parameters print
function Base.show(io::IO, reg::ArrayReg{D,T,MT}) where {D,T,MT}
    print(io, "ArrayReg{$D, $T, $(nameof(MT))...}")
    print(io, "\n    active qudits: ", nactive(reg), "/", nqudits(reg))
    print(io, "\n    nlevel: ", nlevel(reg))
end

function Base.show(io::IO, reg::BatchedArrayReg{D,T,MT}) where {D,T,MT}
    print(io, "BatchedArrayReg{$D, $T, $(nameof(MT))...}")
    print(io, "\n    active qudits: ", nactive(reg), "/", nqudits(reg))
    print(io, "\n    nlevel: ", nlevel(reg))
    print(io, "\n    nbatch: ", nbatch(reg))
end

"""
    mutual_information(reg::AbstractArrayReg, part1, part2)

Compute the mutual information between locations `part1` and locations `part2` in a quantum state `reg`.
"""
function mutual_information(reg::AbstractArrayReg, part1, part2)
    von_neumann_entropy(reg, part1) .+ von_neumann_entropy(reg, part2) .- von_neumann_entropy(reg, part1 ∪ part2)
end

"""
    von_neumann_entropy(reg::AbstractArrayReg, part)
    von_neumann_entropy(ρ::DensityMatrix)

The entanglement entropy between `part` and the rest part in quantum state `reg`.
If the input is a density matrix, it returns the entropy of a mixed state.
"""
von_neumann_entropy(reg::BatchedArrayReg, part) = von_neumann_entropy.(reg, Ref(part))
von_neumann_entropy(reg::ArrayReg, part) = von_neumann_entropy(density_matrix(reg, part))

function Base.iterate(it::Union{BatchedArrayReg{D}, AdjointRegister{D, <:BatchedArrayReg{D}}} where D, state = 1)
    if state > nbatch(it)
        return nothing
    else
        return viewbatch(it, state), state + 1
    end
end

Base.length(r::BatchedArrayReg) = r.nbatch
Base.length(r::AdjointRegister{D, <:BatchedArrayReg{D}}) where {D} = length(parent(r))

"""
    nbatch(register) -> Int

Returns the number of batches.
"""
nbatch(r::BatchedArrayReg) = r.nbatch
nbatch(r::ArrayReg) = NoBatch()
nbatch(r::AdjointArrayReg) = nbatch(parent(r))
