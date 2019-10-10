using YaoBase, BitBasis
import BitBasis: BitStr, BitStr64

export ArrayReg,
    AdjointArrayReg,
    ArrayRegOrAdjointArrayReg,
    transpose_storage,
    # YaoBase
    nqubits,
    nactive,
    nremain,
    nbatch,
    viewbatch,
    addbits!,
    insert_qubits!,
    datatype,
    probs,
    reorder!,
    invorder!,
    collapseto!,
    fidelity,
    tracedist,
    # YaoBase deprecated
    addbit!,
    reset!,
    measure_reset!,
    # additional
    state,
    statevec,
    relaxedvec,
    rank3,
    # BitBasis
    @bit_str,
    hypercubic,
    # initialization
    product_state,
    zero_state,
    rand_state,
    uniform_state,
    oneto

"""
    ArrayReg{B, T, MT <: AbstractMatrix{T}} <: AbstractRegister{B}

Simulated full amplitude register type, it uses an array to represent
corresponding one or a batch of quantum states. `B` is the batch size, `T`
is the numerical type for each amplitude, it is `ComplexF64` by default.
"""
mutable struct ArrayReg{B, T, MT <: AbstractMatrix{T}} <: AbstractRegister{B}
    state::MT
end

const AdjointArrayReg{B, T, MT} = AdjointRegister{B, ArrayReg{B, T, MT}}
const ArrayRegOrAdjointArrayReg{B, T, MT} = Union{ArrayReg{B, T, MT}, AdjointRegister{B, ArrayReg{B, T, MT}}}

"""
    ArrayReg{B}(raw)
    ArrayReg(raw::AbstractVecOrMat)

Construct an array register from a raw array. The size of batch should be declared
explicitly. The batch size will be `size(raw, 2)` by default.

!!! warning

    `ArrayReg` constructor will not normalize the quantum state. If you need a
    normalized quantum state remember to use `normalize!(register)` on the register or
    normalize the input raw array with `normalize` or [`batched_normalize!`](@ref).
"""
function ArrayReg{B}(raw::MT) where {B, T, MT <: AbstractMatrix{T}}
    ispow2(size(raw, 1)) || throw(DimensionMismatch("Expect first dimension size to be power of 2"))
    if !(ispow2(size(raw, 2) ÷ B) && size(raw, 2) % B == 0)
        throw(DimensionMismatch("Expect second dimension size to be an integral multiple of batch size $B"))
    end
    return ArrayReg{B, T, MT}(raw)
end

"""
    datatype(register) -> Int

Returns the numerical data type used by register.

!!! note

    `datatype` is not the same with `eltype`, since `AbstractRegister` family
    is not exactly the same with `AbstractArray`, it is an iterator of several
    registers.
"""
YaoBase.@interface datatype(r::ArrayReg{B, T}) where {B, T} = T

function _warn_type(raw::AbstractArray{T}) where T
    T <: Complex || @warn "Input type of `ArrayReg` is not Complex, got $(eltype(raw))"
end

ArrayReg(raw::AbstractVector) = (_warn_type(raw); ArrayReg(reshape(raw, :, 1)))
ArrayReg(raw::AbstractMatrix) = (_warn_type(raw); ArrayReg{size(raw, 2)}(raw))
ArrayReg(raw::AbstractArray{<:Any, 3}) = (_warn_type(raw); ArrayReg{size(raw, 3)}(reshape(raw, size(raw, 1), :)))

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
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 4/4

julia> ArrayReg(ComplexF32, bit"1010")
ArrayReg{1, Complex{Float32}, Array...}
    active qubits: 4/4
```
"""
ArrayReg(bitstr::BitStr) = ArrayReg(ComplexF64, bitstr)
ArrayReg(::Type{T}, bitstr::BitStr) where T = ArrayReg{1}(T, bitstr)
ArrayReg{B}(bitstr::BitStr) where B = ArrayReg{B}(ComplexF64, bitstr)
ArrayReg{B}(::Type{T}, bitstr::BitStr) where {B, T} = ArrayReg{B}(onehot(T, bitstr, B))


"""
    ArrayReg(r::ArrayReg)

Initialize a new `ArrayReg` by an existing `ArrayReg`. This is equivalent
to `copy`.
"""
ArrayReg(r::ArrayReg{B}) where B = ArrayReg{B}(copy(r.state))

transpose_storage(reg::ArrayReg{B,T,<:Transpose}) where {B,T} = ArrayReg{B}(copy(reg.state))
transpose_storage(reg::ArrayReg{B,T}) where {B,T} = ArrayReg{B}(transpose(copy(transpose(reg.state))))

Base.copy(r::ArrayReg) = ArrayReg(r)
Base.similar(r::ArrayRegOrAdjointArrayReg{B}) where B = ArrayReg{B}(similar(state(r)))

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
YaoBase.nqubits(r::ArrayReg{B}) where B = log2i(length(r.state) ÷ B)
YaoBase.nactive(r::ArrayReg) = log2dim1(r.state)
YaoBase.viewbatch(r::ArrayReg, ind::Int) = @inbounds ArrayReg{1}(view(rank3(r), :, :, ind))

function YaoBase.addbits!(r::ArrayReg, n::Int)
    raw = state(r); M, N = size(raw)
    r.state = similar(r.state, M * (1 << n), N)
    fill!(r.state, 0)
    r.state[1:M, :] = raw
    return r
end

function YaoBase.insert_qubits!(reg::ArrayReg{B}, loc::Int; nqubits::Int=1) where B
    na = nactive(reg)
    focus!(reg, 1:loc-1)
    reg2 = join(zero_state(nqubits; nbatch=B), reg) |> relax! |> focus!((1:na+nqubits)...)
    reg.state = reg2.state
    reg
end

function YaoBase.probs(r::ArrayReg{1})
    if size(r.state, 2) == 1
        return vec(r.state .|> abs2)
    else
        return dropdims(sum(r.state .|> abs2, dims=2), dims=2)
    end
end

function YaoBase.probs(r::ArrayReg{B}) where B
    if size(r.state, 2) == B
        return r.state .|> abs2
    else
        probs = r |> rank3 .|> abs2
        return dropdims(sum(probs, dims=2), dims=2)
    end
end

function YaoBase.reorder!(r::ArrayReg, orders)
    @inbounds for i in 1:size(r.state, 2)
        r.state[:,i] = reorder(r.state[:, i], orders)
    end
    return r
end

function YaoBase.collapseto!(r::ArrayReg, bit_config::BitStr=0)
    fill!(r.state, 0)
    r.state[Int64(bit_config)+1,:] .= 1
    return r
end

"""
    fidelity(r1::ArrayReg, r2::ArrayReg)

Calcuate the fidelity between `r1` and `r2`, if `r1` or `r2` is not pure state
(`nactive(r) != nqubits(r)`), the fidelity is calcuated by purification. See also
[`pure_state_fidelity`](@ref), [`purification_fidelity`](@ref).
"""
function YaoBase.fidelity(r1::ArrayReg{B}, r2::ArrayReg{B}) where B
    state1 = rank3(r1); state2 = rank3(r2)
    size(state1) == size(state2) || throw(DimensionMismatch("Register size not match!"))
    if size(state1, 2) == 1
        return map(b->pure_state_fidelity(state1[:,1,b], state2[:,1,b]), 1:B)
    else
        return map(b->purification_fidelity(state1[:,:,b], state2[:,:,b]), 1:B)
    end
end

YaoBase.tracedist(r1::ArrayReg{B}, r2::ArrayReg{B}) where B = tracedist(ρ(r1), ρ(r2))


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

Return a matrix (vector) for B>1 (B=1) as a vector representation of state, with all qubits activated.
See also [`state`](@ref), [`statevec`](@ref).
"""
relaxedvec(r::ArrayReg{B}) where B = reshape(state(r), :, B)
relaxedvec(r::ArrayReg{1}) = vec(state(r))

"""
    hypercubic(r::ArrayReg) -> AbstractArray

Return the hypercubic form (high dimensional tensor) of this register, only active qubits are considered.
See also [`rank3`](@ref).
"""
BitBasis.hypercubic(r::ArrayRegOrAdjointArrayReg) = reshape(state(r), ntuple(i->2, Val(nactive(r)))..., :)

"""
    rank3(r::ArrayReg)

Return the rank 3 tensor representation of state,
the 3 dimensions are (activated space, remaining space, batch dimension).
See also [`rank3`](@ref).
"""
rank3(r::ArrayRegOrAdjointArrayReg{B}) where B = reshape(state(r), size(state(r), 1), :, B)

"""
    join(regs...)

concat a list of registers `regs` to a larger register, each register should
have the same batch size. See also [`repeat`](@ref).
"""
Base.join(rs::ArrayReg{B}...) where B = _join(join_datatype(rs...), rs...)
Base.join(r::ArrayReg) = r

function _join(::Type{T}, rs::ArrayReg{B}...) where {T, B}
    state = batched_kron(rank3.(rs)...)
    return ArrayReg{B}(reshape(state, size(state, 1), :))
end

join_datatype(r::ArrayReg{B, T}, rs::ArrayReg{B}...) where {B, T} = join_datatype(T, r, rs...)
join_datatype(::Type{T}, r::ArrayReg{B, T1}, rs::ArrayReg{B}...) where {T, T1, B} =
    join_datatype(promote_type(T, T1), rs...)
join_datatype(::Type{T}) where T = T


# initialization methods
"""
    product_state([T=ComplexF64], bit_str; nbatch=1)

Create an [`ArrayReg`](@ref) with bit string literal
defined with [`@bit_str`](@ref). See also [`zero_state`](@ref),
[`rand_state`](@ref), [`uniform_state`](@ref).

# Examples

```jldoctest; setup=:(using YaoArrayRegister)
julia> product_state(bit"100"; nbatch=2)
ArrayReg{2, Complex{Float64}, Array...}
    active qubits: 3/3

julia> product_state(ComplexF32, bit"101"; nbatch=2)
ArrayReg{2, Complex{Float32}, Array...}
    active qubits: 3/3
```
"""
product_state(bit_str::BitStr; nbatch::Int=1) = product_state(ComplexF64, bit_str; nbatch=nbatch)

"""
    product_state([T=ComplexF64], total::Int, bit_config::Integer; nbatch=1, no_transpose_storage=false)

Create an [`ArrayReg`](@ref) with bit configuration `bit_config`, total number of bits `total`.
See also [`zero_state`](@ref), [`rand_state`](@ref), [`uniform_state`](@ref).

# Examples

```jldoctest; setup=:(using YaoArrayRegister)
julia> product_state(4, 3; nbatch=2)
ArrayReg{2, Complex{Float64}, Array...}
    active qubits: 4/4

julia> product_state(4, 0b1001; nbatch=2)
ArrayReg{2, Complex{Float64}, Array...}
    active qubits: 4/4

julia> product_state(ComplexF32, 4, 0b101)
ArrayReg{1, Complex{Float32}, Array...}
    active qubits: 4/4
```

!!! warning

    This interface will not check whether the number of required digits
    for the bit configuration matches the total number of bits.
"""
product_state(total::Int, bit_config::Integer; kwargs...) = product_state(ComplexF64, total, bit_config; kwargs...)

product_state(::Type{T}, bit_str::BitStr{N}; kwargs...) where {T,N} = product_state(T, N, buffer(bit_str); kwargs...)

function product_state(::Type{T}, total::Int, bit_config::Integer; nbatch::Int=1, no_transpose_storage::Bool=false) where T
    if nbatch == 1 || no_transpose_storage
        raw = onehot(T, total, bit_config, nbatch)
    else
        raw = zeros(T, nbatch, 1<<total)
        raw[:,Int(bit_config)+1] .= 1
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
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 4/4

julia> zero_state(ComplexF32, 4)
ArrayReg{1, Complex{Float32}, Array...}
    active qubits: 4/4

julia> zero_state(ComplexF32, 4; nbatch=3)
ArrayReg{3, Complex{Float32}, Array...}
    active qubits: 4/4
```
"""
zero_state(n::Int; kwargs...) = zero_state(ComplexF64, n; kwargs...)
zero_state(::Type{T}, n::Int; kwargs...) where T = product_state(T, n, 0; kwargs...)


"""
    rand_state([T=ComplexF64], n::Int; nbatch=1, no_transpose_storage=false)

Create a random [`ArrayReg`](@ref) with total number of qubits `n`.

# Examples

```jldoctest; setup=:(using YaoArrayRegister)
julia> rand_state(4)
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 4/4

julia> rand_state(ComplexF64, 4)
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 4/4

julia> rand_state(ComplexF64, 4; nbatch=2)
ArrayReg{2, Complex{Float64}, Array...}
    active qubits: 4/4
```
"""
rand_state(n::Int; kwargs...) = rand_state(ComplexF64, n; kwargs...)

function rand_state(::Type{T}, n::Int; nbatch::Int=1, no_transpose_storage::Bool=false) where T
    raw = nbatch == 1 || no_transpose_storage ? randn(T, 1<<n, nbatch) : transpose(randn(T, nbatch, 1<<n))
    return normalize!(ArrayReg{nbatch}(raw))
end

"""
    uniform_state([T=ComplexF64], n; nbatch=1, no_transpose_storage=false)

Create a uniform state: ``\\frac{1}{2^n} \\sum_k |k⟩``. This state
can also be created by applying [`H`](@ref) (Hadmard gate) on ``|00⋯00⟩`` state.

# Example

```jldoctest; setup=:(using YaoArrayRegister)
julia> uniform_state(4; nbatch=2)
ArrayReg{2, Complex{Float64}, Array...}
    active qubits: 4/4

julia> uniform_state(ComplexF32, 4; nbatch=2)
ArrayReg{2, Complex{Float64}, Array...}
    active qubits: 4/4
```
"""
uniform_state(n::Int; kwargs...) = uniform_state(ComplexF64, n; kwargs...)
function uniform_state(::Type{T}, n::Int; nbatch::Int=1, no_transpose_storage::Bool=false) where T
    raw = nbatch == 1 || no_transpose_storage ? ones(T, 1<<n, nbatch) : transpose(ones(T, nbatch, 1<<n))
    normalize!(ArrayReg{nbatch}(raw))
end

"""
    oneto(r::ArrayReg, n::Int=nqubits(r))

Returns an `ArrayReg` with `1:n` qubits activated.
"""
oneto(r::ArrayReg{B}, n::Int=nqubits(r)) where B = ArrayReg{B}(reshape(copy(r.state), 1<<n, :))

"""
    oneto(n::Int) -> f(register)

Like `oneto(register, n)`, but the input `register` is delayed.
"""
oneto(n::Int) = r->oneto(r, n)

"""
    repeat(register, n)

Create an [`ArrayReg`](@ref) by copying the original `register` for `n` times on
batch dimension.

# Example

```jldoctest; setup=:(using YaoArrayRegister)
julia> repeat(ArrayReg{3}(bit"101"), 4)
ArrayReg{12, Complex{Float64}, Array...}
    active qubits: 3/3
```
"""
Base.repeat(r::ArrayReg{B}, n::Int) where B = ArrayReg{B * n}(hcat((state(r) for k in 1:n)...))

# NOTE: overload this to make printing more compact
#       but do not alter the way how type parameters print
function Base.summary(io::IO, r::ArrayReg{B, T, MT}) where {B, T, MT}
    print(io, "ArrayReg{$B, $T, $(nameof(MT))...}")
end
