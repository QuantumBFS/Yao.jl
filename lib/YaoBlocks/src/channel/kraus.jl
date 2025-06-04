"""
    KrausChannel{D} <: AbstractQuantumChannel{D}
    KrausChannel(operators)

Create a Kraus representation of a quantum channel, where `operators` is a list of Kraus operators.
"""
struct KrausChannel{D} <: AbstractQuantumChannel{D}
    n::Int
    operators::Vector{AbstractBlock{D}}
    function KrausChannel(operators::Vector{AbstractBlock{D}}) where D
        n = _check_block_sizes(operators)
        new{D}(n, operators)
    end
end
function KrausChannel(it)
    length(it) == 0 && error("The input operator list size can not be 0!")
    D = nlevel(first(it))
    KrausChannel(collect(AbstractBlock{D}, it))
end
nqudits(uc::KrausChannel) = uc.n

function YaoAPI.unsafe_apply!(r::DensityMatrix{D,T}, x::PutBlock{D,C,<:KrausChannel}) where {D,C,T}
    unsafe_apply!(r, KrausChannel([PutBlock(x.n, operator, x.locs) for operator in x.content.operators], x.content.probs))
end
function YaoAPI.unsafe_apply!(r::DensityMatrix{D,T}, x::KrausChannel) where {D,T}
    r0 = copy(r)
    # first
    unsafe_apply!(r, first(x.operators))
    for o in x.operators[2:end-1]
        r.state .+= unsafe_apply!(copy(r0), o).state
    end
    # last
    r.state .+= unsafe_apply!(r0, last(x.operators)).state
    return r
end

subblocks(x::KrausChannel) = x.operators
chsubblocks(x::KrausChannel, it) = KrausChannel(collect(it))
occupied_locs(x::KrausChannel) = union(occupied_locs.(x.operators)...)

function cache_key(x::KrausChannel)
    return hash(ntuple(i -> hash(x.operators[i]), length(x.operators)))
end

function Base.:(==)(lhs::KrausChannel, rhs::KrausChannel)
    return (lhs.n == rhs.n) && (lhs.operators == rhs.operators)
end

Base.adjoint(x::KrausChannel) = KrausChannel(adjoint.(x.operators))

"""
    kraus_channel(operators) -> KrausChannel

Returns a [`KrausChannel`](@ref) instance, where ``operators` is a list of operators.
The kraus channel is defined as below

```math
\\phi(\\rho) = \\sum_i K_i ρ K_i^\\dagger,
```

where ``\\rho`` in a [`DensityMatrix`](@ref) as the register to apply on, ``K_i`` is the i-th operator in `operators`.

### Examples

```jldoctest; setup=:(using Yao)
julia> kraus_channel([X, Y, Z])
nqubits: 1
kraus_channel
├─ [0.1] X
├─ [0.2] Y
└─ [0.7] Z
```
"""
kraus_channel(operators, probs::AbstractVector) = KrausChannel(operators, probs)

function SuperOp(x::KrausChannel)
    n = x.n
    D = nlevel(first(x.operators))
    operators = AbstractBlock{D}[sqrt(pi) * oi for (pi, oi) in zip(x.probs, x.operators)]
    return SuperOp(n, operators)
end


