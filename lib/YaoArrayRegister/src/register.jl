import BitBasis: BitStr, BitStr64

abstract type AbstractArrayReg{D,T,AT} <: AbstractRegister{D} end

struct NoBatch end
_asint(x::Int) = x
_asint(::NoBatch) = 1

# interfaces
YaoAPI.nremain(r::AbstractRegister) = nqudits(r) - nactive(r)
YaoAPI.nlevel(r::AbstractRegister{D}) where {D} = D
YaoAPI.nqubits(r::AbstractRegister{2}) = nqudits(r)

# conrete implementations

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
YaoAPI.viewbatch(r::ArrayReg, ind::Int) = ind == 1 ? r : error("Index `$ind` out of bounds, should be `1`.")

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
                "Expect second dimension size to be $D^n multiple of batch size $B",
            ),
        )
    end
end

function _warn_type(raw::AbstractMatrix{T}) where T
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

Base.parent(reg::AdjointRegister) = reg.parent

function Base.summary(io::IO, reg::AdjointRegister{B,RT}) where {B,RT}
    print(io, "adjoint(", summary(reg.parent), ")")
end

"""
    adjoint(register) -> register

Lazy adjoint for quantum registers.
"""
Base.adjoint(reg::AbstractRegister) = AdjointRegister(reg)
Base.adjoint(reg::AdjointRegister) = parent(reg)

YaoAPI.viewbatch(reg::AdjointRegister, i::Int) = adjoint(viewbatch(parent(reg), i))

for FUNC in [:nqudits, :nremain, :nactive]
    @eval YaoAPI.$FUNC(r::AdjointRegister) = $FUNC(r.parent)
end

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

### Examples

```jldoctest; setup=:(using Yao)
julia> arrayreg(bit"1010")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 4/4
    nlevel: 2

julia> arrayreg(ComplexF32, bit"1010")
ArrayReg{2, ComplexF32, Array...}
    active qubits: 4/4
    nlevel: 2
```
"""
arrayreg(bitstr::BitStr; nbatch::Union{Int,NoBatch}=NoBatch()) = arrayreg(ComplexF64, bitstr; nbatch=nbatch)
arrayreg(::Type{T}, bitstr::BitStr; nbatch::Union{Int,NoBatch}=NoBatch()) where {T} = arrayreg(onehot(T, bitstr; nbatch=_asint(nbatch)); nbatch=nbatch, nlevel=2)

"""
    transpose_storage(register) -> register

Transpose the register storage. Sometimes transposed storage provides better performance for batched simulation.
"""
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
YaoAPI.nqudits(r::AbstractArrayReg{2}) = log2i(length(r.state) ÷ _asint(nbatch(r)))
YaoAPI.nqudits(r::AbstractArrayReg{D}) where {D} = logdi(length(r.state) ÷ _asint(nbatch(r)), D)
YaoAPI.nactive(r::AbstractArrayReg{D}) where {D} = logdi(size(r.state, 1), D)
YaoAPI.viewbatch(r::BatchedArrayReg{D}, ind::Int) where D = @inbounds ArrayReg{D}(view(rank3(r), :, :, ind))

YaoAPI.append_qudits!(n::Int) = @λ(register -> append_qudits!(register, n))
function YaoAPI.append_qudits!(r::AbstractArrayReg{D,T}, n::Int) where {D,T}
    raw = state(r)
    M, N = size(raw)
    r.state = similar(r.state, M * (D ^ n), N)   # NOTE: does not preserve adjoint
    fill!(r.state, zero(T))
    r.state[1:M, :] = raw
    return r
end
YaoAPI.append_qubits!(reg::AbstractRegister{2}, nqubits::Int) = append_qudits!(reg, nqubits)
YaoAPI.append_qubits!(nqubits::Int) =
    @λ(register -> append_qubits!(register, nqubits))

YaoAPI.insert_qubits!(loc::Int, nqubits::Int) =
    @λ(register -> insert_qubits!(register, loc, nqubits))
YaoAPI.insert_qubits!(reg::AbstractRegister{2}, loc::Int, nqubits::Int) = insert_qudits!(reg, loc, nqubits)
YaoAPI.insert_qudits!(loc::Int, nqudits::Int) =
    @λ(register -> insert_qudits!(register, loc, nqudits))
function YaoAPI.insert_qudits!(reg::AbstractArrayReg{D}, loc::Int, nqudits::Int) where D
    na = nactive(reg)
    focus!(reg, 1:loc-1)
    reg2 = join(zero_state_like(reg, nqudits), reg) |> relax! |> focus!((1:na+nqudits)...)
    reg.state = reg2.state
    reg
end

"""
    zero_state_like(register, n) -> AbstractRegister

Create a register initialized to zero from an existing one.

### Examples

```jldoctest; setup=:(using Yao)
julia> reg = rand_state(3; nbatch=2)
BatchedArrayReg{2, ComplexF64, Transpose...}
    active qubits: 3/3
    nlevel: 2
    nbatch: 2
```
"""
function zero_state_like(reg::ArrayReg{D,T}, nqudits::Int) where {D,T}
    state = similar(reg.state, D^nqudits, _asint(nbatch(reg)))   # NOTE: does not preserve adjoint
    fill!(state,zero(T))
    state[1,1:1] .= Ref(one(T))  # broadcast to make it GPU compatible.
    return ArrayReg{D}(state)
end
function zero_state_like(reg::BatchedArrayReg{D,T}, nqudits::Int) where {D,T}
    state = similar(reg.state, D^nqudits, _asint(nbatch(reg)))   # NOTE: does not preserve adjoint
    fill!(state, zero(T))
    reshape(state, :, reg.nbatch)[1,:] .= Ref(one(T))  # broadcast to make it GPU compatible.
    return BatchedArrayReg{D}(state, reg.nbatch)
end

function YaoAPI.probs(r::ArrayReg)
    if size(r.state, 2) == 1
        return vec(r.state .|> abs2)
    else
        return dropdims(sum(r.state .|> abs2, dims = 2), dims = 2)
    end
end

function YaoAPI.probs(r::BatchedArrayReg)
    if size(r.state, 2) == nbatch(r)
        return r.state .|> abs2
    else
        probs = r |> rank3 .|> abs2
        return dropdims(sum(probs, dims = 2), dims = 2)
    end
end

YaoAPI.invorder!(r::AbstractRegister) = reorder!(r, Tuple(nactive(r):-1:1))
function YaoAPI.reorder!(r::AbstractArrayReg, orders)
    @assert nactive(r) == length(orders)
    st = reshape(r.state,fill(nlevel(r),nactive(r))...,size(r.state,2))
    r.state = reshape(permutedims(st, sortperm([collect(orders)..., length(orders)+1])), size(r.state))
    return r
end

function YaoAPI.collapseto!(r::AbstractArrayReg, bit_config::Integer)
    st = normalize!(r.state[Int(bit_config)+1, :])
    fill!(r.state, 0)
    r.state[Int(bit_config)+1, :] .= st
    return r
end

function YaoAPI.fidelity(r1::BatchedArrayReg{D}, r2::BatchedArrayReg{D}) where {D}
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

function YaoAPI.fidelity(r1::BatchedArrayReg, r2::ArrayReg)
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

YaoAPI.fidelity(r1::ArrayReg, r2::BatchedArrayReg) = YaoAPI.fidelity(r2, r1)

function YaoAPI.fidelity(r1::ArrayReg, r2::ArrayReg)
    state1 = state(r1)
    state2 = state(r2)
    nqudits(r1) == nqudits(r2) || throw(DimensionMismatch("Register size not match!"))

    if size(state1, 2) == 1
        return pure_state_fidelity(state1[:, 1], state2[:, 1])
    else
        return purification_fidelity(state1, state2)
    end
end

YaoAPI.tracedist(r1::ArrayReg, r2::ArrayReg) = tracedist(density_matrix(r1), density_matrix(r2))
YaoAPI.tracedist(r1::BatchedArrayReg, r2::BatchedArrayReg) = tracedist.(r1, r2)


# properties
"""
    state(register::AbstractArrayReg) -> Matrix

Returns the raw array storage of `register`. See also [`statevec`](@ref).
"""
state(r::AbstractArrayReg) = r.state
state(r::AdjointArrayReg) = adjoint(state(parent(r)))

"""
    statevec(r::ArrayReg) -> array

Return a state matrix/vector by droping the last dimension of size 1 (i.e. `nactive(r) = nqudits(r)`).
See also [`state`](@ref).

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

Return the hypercubic representation (high dimensional tensor) of this register, only active qudits are considered.
See also [`rank3`](@ref) and [`state`](@ref).
"""
BitBasis.hypercubic(r::ArrayRegOrAdjointArrayReg) =
    reshape(state(r), ntuple(i -> nlevel(r), Val(nactive(r)))..., :)

"""
    rank3(r::ArrayReg)

Return the rank 3 tensor representation of state, the 3 dimensions are (activated space, remaining space, batch dimension).
See also [`hypercubic`](@ref) and [`state`](@ref).
"""
function rank3(r::ArrayRegOrAdjointArrayReg)
    s = state(r)
    reshape(s, size(s, 1), :, _asint(nbatch(r)))
end

"""
    join(regs...)

concatenate a list of registers `regs` to a larger register, each register should
have the same batch size. See also [`clone`](@ref).

```jldoctest; setup=:(using Yao)
julia> reg = join(product_state(bit"111"), zero_state(3))
ArrayReg{2, ComplexF64, Array...}
    active qubits: 6/6
    nlevel: 2

julia> measure(reg; nshots=3)
3-element Vector{DitStr{2, 6, Int64}}:
 111000 ₍₂₎
 111000 ₍₂₎
 111000 ₍₂₎
```
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
    product_state([T=ComplexF64], dit_str; nbatch=NoBatch(), no_transpose_storage=false)
    product_state([T=ComplexF64], nbits::Int, val::Int; nbatch=NoBatch(), nlevel=2, no_transpose_storage=false)
    product_state([T=ComplexF64], vector; nbatch=NoBatch(), nlevel=2, no_transpose_storage=false)

Create an [`ArrayReg`](@ref) of product state.
The configuration can be specified with a dit string, which can be defined with [`@bit_str`](@ref) or [`@dit_str`](@ref).
Or equivalently, it can be specified explicitly with `nbits`, `val` and `nlevel`.
See also [`zero_state`](@ref), [`rand_state`](@ref), [`uniform_state`](@ref).

### Examples

```jldoctest; setup=:(using Yao)
julia> reg = product_state(dit"120;3"; nbatch=2)
BatchedArrayReg{3, ComplexF64, Transpose...}
    active qudits: 3/3
    nlevel: 3
    nbatch: 2

julia> measure(reg)
1×2 Matrix{BitBasis.DitStr64{3, 3}}:
 120 ₍₃₎  120 ₍₃₎

julia> product_state(bit"100"; nbatch=2);

julia> r1 = product_state(ComplexF32, bit"001"; nbatch=2);

julia> r2 = product_state(ComplexF32, [0, 0, 1]; nbatch=2);

julia> r3 = product_state(ComplexF32, 3, 0b001; nbatch=2);

julia> r1 ≈ r2   # because we read bit strings from right to left, vectors from left to right.
true

julia> r1 ≈ r3
true
```
"""
function product_state(::Type{T}, bit_str::DitStr{D,N,Ti};
        nbatch::Union{Int,NoBatch} = NoBatch(),
        no_transpose_storage::Bool = false,
        ) where {D,T,N,Ti}
    if nbatch isa NoBatch || no_transpose_storage
        raw = zeros(T, D ^ N, _asint(nbatch))
    else
        # transposed storage
        raw = zeros(T, _asint(nbatch), D ^ N)
        raw = transpose(raw)
    end
    raw[buffer(bit_str)+1,:] .= Ref(one(T))
    return arrayreg(raw; nbatch=nbatch, nlevel=D)
end
# vector input
function product_state(::Type{T}, bit_configs::AbstractVector;
        nlevel::Int=2, kwargs...) where {T}
    return product_state(T, DitStr{nlevel}(bit_configs); kwargs...)
end
# integer input
function product_state(::Type{T}, total::Int, val::Integer;
        nlevel::Int=2,
        kwargs...) where {T}
    product_state(T, DitStr{nlevel,total}(val); kwargs...)
end

# default type
product_state(dit_str::DitStr; kwargs...) =
    product_state(ComplexF64, dit_str; kwargs...)
product_state(vector::AbstractVector; kwargs...) =
    product_state(ComplexF64, vector; kwargs...)
product_state(total::Int, val::Integer; kwargs...) =
    product_state(ComplexF64, total, val; kwargs...)

"""
    zero_state([T=ComplexF64], n::Int; nbatch::Int=NoBatch())

Create an [`AbstractArrayReg`](@ref) that initialized to state ``|0\\rangle^{\\otimes n}``.
See also [`product_state`](@ref), [`rand_state`](@ref), [`uniform_state`](@ref) and [`ghz_state`](@ref).

### Examples

```jldoctest; setup=:(using Yao)
julia> zero_state(4)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 4/4
    nlevel: 2

julia> zero_state(ComplexF32, 4)
ArrayReg{2, ComplexF32, Array...}
    active qubits: 4/4
    nlevel: 2

julia> zero_state(ComplexF32, 4; nbatch=3)
BatchedArrayReg{2, ComplexF32, Transpose...}
    active qubits: 4/4
    nlevel: 2
    nbatch: 3
```
"""
zero_state(n::Int; kwargs...) = zero_state(ComplexF64, n; kwargs...)
zero_state(::Type{T}, n::Int; kwargs...) where {T} = product_state(T, n, 0; kwargs...)

"""
    ghz_state([T=ComplexF64], n::Int; nbatch::Int=NoBatch())

Create a GHZ state (or a cat state) that defined as

```math
\\frac{|0\\rangle^{\\otimes n} + |1\\rangle^{\\otimes n}}{\\sqrt{2}}.
```

### Examples

```jldoctest; setup=:(using Yao)
julia> ghz_state(4)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 4/4
    nlevel: 2
```
"""
ghz_state(n::Int; kwargs...) = ghz_state(ComplexF64, n; kwargs...)
function ghz_state(::Type{T}, n::Int; kwargs...) where {T}
    reg = zero_state(T, n; kwargs...)
    reg.state[1,:] .= Ref(sqrt(inv(T(2))))  # make symbolic feel better
    reg.state[end,:] .= Ref(sqrt(inv(T(2))))
    return reg
end

"""
    rand_state([T=ComplexF64], n::Int; nbatch=NoBatch(), no_transpose_storage=false)

Create a random [`AbstractArrayReg`](@ref) with total number of qudits `n`.

### Examples

```jldoctest; setup=:(using Yao)
julia> rand_state(4)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 4/4
    nlevel: 2

julia> rand_state(ComplexF64, 4)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 4/4
    nlevel: 2

julia> rand_state(ComplexF64, 4; nbatch=2)
BatchedArrayReg{2, ComplexF64, Transpose...}
    active qubits: 4/4
    nlevel: 2
    nbatch: 2
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
    uniform_state([T=ComplexF64], n; nbatch=NoBatch(), no_transpose_storage=false)

Create a uniform state:
```math
\\frac{1}{\\sqrt{2^n}} \\sum_{k=0}^{2^{n}-1} |k\\rangle.
```
This state can also be created by applying [`H`](@ref) (Hadmard gate) on ``|00⋯00⟩`` state.

### Example

```jldoctest; setup=:(using Yao)
julia> uniform_state(4; nbatch=2)
BatchedArrayReg{2, ComplexF64, Transpose...}
    active qubits: 4/4
    nlevel: 2
    nbatch: 2

julia> uniform_state(ComplexF32, 4; nbatch=2)
BatchedArrayReg{2, ComplexF32, Transpose...}
    active qubits: 4/4
    nlevel: 2
    nbatch: 2
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

Returns an register with `1:n` qudits activated, which is faster than the general purposed [`focus`](@ref) function.
"""
oneto(n::Int) = r -> oneto(r, n)
oneto(r::AbstractArrayReg{D}, n::Int = nqudits(r)) where {D} =
    arrayreg(reshape(copy(r.state), D ^ n, :), nbatch=nbatch(r), nlevel=D)
oneto(r::AbstractArrayReg{D,T,<:Transpose}, n::Int = nqudits(r)) where {D,T} =
    transpose_storage(arrayreg(reshape(r.state, D ^ n, :); nbatch=nbatch(r), nlevel=D))

YaoAPI.clone(r::AbstractArrayReg{D}, n::Int) where D =
    BatchedArrayReg{D}(hcat((state(r) for k = 1:n)...), n * _asint(nbatch(r)))

# NOTE: overload this to make printing more compact
#       but do not alter the way how type parameters print
qubit_type(::AbstractArrayReg{2}) = "qubits"
qubit_type(::AbstractArrayReg) = "qudits"

function Base.show(io::IO, reg::ArrayReg{D,T,MT}) where {D,T,MT}
    print(io, "ArrayReg{$D, $T, $(nameof(MT))...}")
    print(io, "\n    active $(qubit_type(reg)): ", nactive(reg), "/", nqudits(reg))
    print(io, "\n    nlevel: ", nlevel(reg))
end

function Base.show(io::IO, reg::BatchedArrayReg{D,T,MT}) where {D,T,MT}
    print(io, "BatchedArrayReg{$D, $T, $(nameof(MT))...}")
    print(io, "\n    active $(qubit_type(reg)): ", nactive(reg), "/", nqudits(reg))
    print(io, "\n    nlevel: ", nlevel(reg))
    print(io, "\n    nbatch: ", nbatch(reg))
end

print_table(reg::AbstractArrayReg; digits::Int=5) = print_table(stdout, reg; digits)
function print_table(io::IO, reg::AbstractArrayReg; digits::Int=5)
    data = rank3(reg)
    for i in basis(reg)
        print(io, "$i   ")
        for b in 1:size(data, 3)
            for r in 1:size(data, 2)
                s = round(data[buffer(i)+1,r,b]; digits)
                print(io, s)
                if r != size(data, 2)
                    print(io, ", ")
                end
            end
            b !== size(data, 3) && print(io, "; ")
        end
        println(io)
    end
end

"""
    mutual_information(reg::AbstractArrayReg, part1, part2)

Compute the mutual information between locations `part1` and locations `part2` in a quantum state `reg`.

### Example

The mutual information of a GHZ state of any two disjoint parts is always equal to ``\\log 2``.

```jldoctest; setup=:(using Yao)
julia> mutual_information(ghz_state(4), (1,), (3,4))
0.6931471805599132
```
"""
function mutual_information(reg::AbstractArrayReg, part1, part2)
    @assert isempty(part1 ∩ part2)
    von_neumann_entropy(reg, part1) .+ von_neumann_entropy(reg, part2) .- von_neumann_entropy(reg, part1 ∪ part2)
end

"""
    von_neumann_entropy(reg::AbstractArrayReg, part)
    von_neumann_entropy(ρ::DensityMatrix)

The entanglement entropy between `part` and the rest part in quantum state `reg`.
If the input is a density matrix, it returns the entropy of a mixed state.

### Example

The Von Neumann entropy of any segment of GHZ state is ``\\log 2``.

```jldoctest; setup=:(using Yao)
julia> von_neumann_entropy(ghz_state(3), (1,2))
0.6931471805599612
```
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
    nbatch(register) -> Union{Int,NoBatch()}

Returns the number of batches.
"""
nbatch(r::BatchedArrayReg) = r.nbatch
nbatch(r::ArrayReg) = NoBatch()
nbatch(r::AdjointArrayReg) = nbatch(parent(r))

"""
    most_probable(reg::AbstractArrayReg{2}, n::Int)

Find `n` most probable qubit configurations in a quantum register and return these configurations as a vector of `BitStr` instances.

### Example

```jldoctest; setup=:(using Yao)
julia> most_probable(ghz_state(3), 2)
2-element Vector{DitStr{2, 3, Int64}}:
 000 ₍₂₎
 111 ₍₂₎
```
"""
function most_probable(reg::ArrayReg{2}, n::Int)
    imax = sortperm(probs(reg); rev=true)[1:n]
    return BitStr{nqubits(reg)}.(imax .- 1)
end

function most_probable(reg::BatchedArrayReg{2}, n::Int)
    res = Matrix{BitStr{nqubits(reg),Int}}(undef, n, reg.nbatch)
    for b = 1:nbatch(reg)
        imax = sortperm(probs(viewbatch(reg, b)); rev=true)[1:n]
        res[:, b] .= BitStr{nqubits(reg)}.(imax .- 1)
    end
    return res
end

"""
    basis(register) -> UnitRange

Returns an `UnitRange` of the all the bits in the Hilbert space of given register.

```jldoctest; setup=:(using Yao)
julia> collect(basis(rand_state(3)))
8-element Vector{DitStr{2, 3, Int64}}:
 000 ₍₂₎
 001 ₍₂₎
 010 ₍₂₎
 011 ₍₂₎
 100 ₍₂₎
 101 ₍₂₎
 110 ₍₂₎
 111 ₍₂₎
```
"""
BitBasis.basis(r::AbstractRegister{D}) where D = basis(DitStr{D,nactive(r),Int})


"""
    partial_tr(locs) -> f(ρ)

Curried version of `partial_tr(ρ, locs)`.
"""
YaoAPI.partial_tr(locs) = @λ(ρ -> partial_tr(ρ, locs))

Base.getindex(reg::ArrayReg{D}, d::DitStr{D}) where D = getindex(reg.state, buffer(d)+1)
Base.getindex(reg::BatchedArrayReg{D}, d::DitStr{D}) where D = getindex(reg.state, buffer(d)+1, :)