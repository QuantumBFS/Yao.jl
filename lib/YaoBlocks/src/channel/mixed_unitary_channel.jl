# NOTE: this can have a better support in YaoIR directly with StatsBase
# as an compiled instruction, but store the probabilities is the best solution
# here

"""
    MixedUnitaryChannel{D, W<:AbstractVector} <: CompositeBlock{D}
    MixedUnitaryChannel(operators, probs)

Create a mixed unitary channel, where `probs` is a real vector that sum up to 1.
The mixed unitary channel is defined as below

```math
\\phi(\\rho) = \\sum_i p_i U_i ρ U_i^\\dagger,
```

where ``\\rho`` in a [`DensityMatrix`](@ref) as the register to apply on, ``p_i`` is the i-th element in `probs`, `U_i` is the i-th operator in `operators`.

### Examples

```jldoctest; setup=:(using Yao)
julia> MixedUnitaryChannel([X, Y, Z], [0.1, 0.2, 0.7])
nqubits: 1
mixed_unitary_channel
├─ [0.1] X
├─ [0.2] Y
└─ [0.7] Z
```
"""
struct MixedUnitaryChannel{D, W<:AbstractVector} <: AbstractQuantumChannel{D}
    n::Int
    operators::Vector{AbstractBlock{D}}
    probs::W

    function MixedUnitaryChannel(operators::Vector{AbstractBlock{D}}, w::AbstractVector) where D
        @assert length(operators) == length(w) && length(w) != 0
        if !(all(x->x>=0, w) && sum(w) ≈ 1)
            error("The probabilities must be ⩾ 0 and its sum must be 1!")
        end
        n = _check_block_sizes(operators)
        new{D,typeof(w)}(n, operators, w)
    end
end

function MixedUnitaryChannel(it, probs)
    length(it) == 0 && error("The input operator list size can not be 0!")
    D = nlevel(first(it))
    MixedUnitaryChannel(collect(AbstractBlock{D}, it), probs)
end
nqudits(uc::MixedUnitaryChannel) = uc.n

function noisy_instruct!(r::DensityMatrix{D,T}, x::MixedUnitaryChannel, locs) where {D,T}
    return unsafe_apply!(r, MixedUnitaryChannel([put(nqudits(r), locs => op) for op in x.operators], x.probs))
end

function YaoAPI.unsafe_apply!(r::DensityMatrix{D,T}, x::MixedUnitaryChannel) where {D,T}
    r0 = copy(r)
    # first
    regscale!(unsafe_apply!(r, first(x.operators)), first(x.probs))
    for (w, o) in zip(x.probs[2:end-1], x.operators[2:end-1])
        r.state .+= w .* unsafe_apply!(copy(r0), o).state
    end
    # last
    r.state .+= last(x.probs) .* unsafe_apply!(r0, last(x.operators)).state
    return r
end

subblocks(x::MixedUnitaryChannel) = x.operators
chsubblocks(x::MixedUnitaryChannel, it) = MixedUnitaryChannel(collect(it), x.probs)
occupied_locs(x::MixedUnitaryChannel) = union(occupied_locs.(x.operators)...)

function cache_key(x::MixedUnitaryChannel)
    key = hash(x.probs)
    for each in x.operators
        key = hash(each, key)
    end
    return key
end

function Base.:(==)(lhs::MixedUnitaryChannel, rhs::MixedUnitaryChannel)
    return (lhs.n == rhs.n) && (lhs.probs == rhs.probs) && (lhs.operators == rhs.operators)
end

Base.adjoint(x::MixedUnitaryChannel) = MixedUnitaryChannel(adjoint.(x.operators), x.probs)

# convert unitary channel to kraus channel and superop
KrausChannel(x::MixedUnitaryChannel{D}) where D = KrausChannel(AbstractBlock{D}[sqrt(f) * oi for (f, oi) in zip(x.probs, x.operators)])
SuperOp(x::MixedUnitaryChannel{D, WT}) where {T, D, WT<:AbstractVector{T}} = SuperOp(Complex{T}, KrausChannel(x))
SuperOp(::Type{T}, x::MixedUnitaryChannel) where T = SuperOp(T, KrausChannel(x))

function LinearAlgebra.kron(x::MixedUnitaryChannel, y::MixedUnitaryChannel)
    return MixedUnitaryChannel([kron(op1, op2) for op1 in x.operators for op2 in y.operators], [px * py for px in x.probs for py in y.probs])
end

### DepolarizingChannel - a special case of mixed unitary channel
"""
    DepolarizingChannel{D, RT<:Real} <: AbstractQuantumChannel{D}
    DepolarizingChannel(n::Int, p::Real; nlevel::Int=2)

Create a global depolarizing channel. For qubit system (D = 2), the depolarizing channel is defined as
```math
\\phi(\\rho) = (1 - p) \\rho + \\frac{p}{4^n} \\sum_{i=1}^{4^n} P_i \\rho P_i^\\dagger,
```
where ``P_i`` is the i-th Pauli operator, ``n`` is the number of qubits, and ``p`` is the probability of the error to occur.

It is different from the kronecker product of the single-qubit depolarizing channel, in which case the errors on different qubits are independent.

### Fields
- `n`: number of qubits.
- `p`: probability of this error to occur.
"""
struct DepolarizingChannel{D, RT<:Real} <: AbstractQuantumChannel{D}
    n::Int
    p::RT
    function DepolarizingChannel{D}(n::Int, p::Real) where {D}
        @assert 0 ≤ p ≤ 1 "The probability must be in [0, 1]!"
        new{D, typeof(p)}(n, p)
    end
end
function DepolarizingChannel(n::Int, p::Real; nlevel::Int=2)
    return DepolarizingChannel{nlevel}(n, p)
end

YaoAPI.nqudits(ch::DepolarizingChannel) = ch.n

function YaoAPI.unsafe_apply!(dm::DensityMatrix{D,T}, ch::DepolarizingChannel{D}) where {D,T}
    regscale!(dm, 1 - ch.p)
    dm.state .+= ch.p/(D^nqubits(dm)) * IMatrix(size(dm.state, 1))
    return dm
end
function noisy_instruct!(r::DensityMatrix{D,T}, x::DepolarizingChannel, locs) where {D,T}
    noisy_instruct!(r, MixedUnitaryChannel(x), locs)
end
subblocks(::DepolarizingChannel) = ()
print_block(io::IO, x::DepolarizingChannel) = print(io, "DepolarizingChannel{$(nqudits(x))}($(x.p))")

function cache_key(x::DepolarizingChannel)
    return hash(x.n, hash(x.p))
end
function Base.:(==)(lhs::DepolarizingChannel, rhs::DepolarizingChannel)
    return (lhs.n == rhs.n) && (lhs.p == rhs.p)
end
Base.adjoint(x::DepolarizingChannel{D}) where D = DepolarizingChannel{D}(x.n, x.p)

function MixedUnitaryChannel(c::DepolarizingChannel{D, RT}) where {D, RT}
    operators = AbstractBlock{D}[]
    for op in Iterators.product([[I2, X, Y, Z] for i=1:c.n]...)
        push!(operators, kron(op...))
    end
    probs = fill(c.p/D^(2*c.n), D^(2*c.n))
    probs[1] += 1 - c.p
    return MixedUnitaryChannel(operators, probs)
end

function SuperOp(::Type{T}, c::DepolarizingChannel{D, RT}) where {T, D, RT}
    N = D^c.n
    # the scaling factor
    i1 = collect(1:N^2)
    j1 = collect(1:N^2)
    v1 = fill(T(1 - c.p), N^2)
    # the tracial part (constant)
    i2 = repeat(collect(1:N+1:N^2), inner=N)
    j2 = repeat(collect(1:N+1:N^2), outer=N)
    v2 = fill(T(c.p/N), length(i2))
    return SuperOp{D}(sparse(vcat(i1, i2), vcat(j1, j2), vcat(v1, v2), N^2, N^2))
end
SuperOp(c::DepolarizingChannel{D, RT}) where {D, RT} = SuperOp(Complex{RT}, c)