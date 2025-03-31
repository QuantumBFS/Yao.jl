abstract type AbstractQuantumChannel{D} <: AbstractBlock{D} end

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
    regscale!(unsafe_apply!(r, first(x.operators)), first(x.probs))
    for (w, o) in zip(x.probs[2:end-1], x.operators[2:end-1])
        r.state .+= w .* unsafe_apply!(copy(r0), o).state
    end
    # last
    r.state .+= last(x.probs) .* unsafe_apply!(r0, last(x.operators)).state
    return r
end

function YaoAPI.unsafe_apply!(r::DensityMatrix{D,T}, 
                              k::KronBlock{D,M,NTuple{M,U}}) where {D,M,T,U<:KrausChannel}
    for (locs, block) in zip(k.locs, k.blocks)
        YaoAPI.unsafe_apply!(r, put(k.n, locs => block))
    end
    return r
end

function mat(::Type{T}, x::KrausChannel) where {T}
    error("`KrausChannel` does not have a matrix representation!")
end

subblocks(x::KrausChannel) = x.operators
chsubblocks(x::KrausChannel, it) = KrausChannel(collect(it), x.probs)
occupied_locs(x::KrausChannel) = union(occupied_locs.(x.operators)...)

function cache_key(x::KrausChannel)
    key = hash(x.probs)
    for each in x.operators
        key = hash(each, key)
    end
    return key
end

function Base.:(==)(lhs::KrausChannel, rhs::KrausChannel)
    return (lhs.n == rhs.n) && (lhs.probs == rhs.probs) && (lhs.operators == rhs.operators)
end

Base.adjoint(x::KrausChannel) = KrausChannel(adjoint.(x.operators), x.probs)

"""
    kraus_channel(operators, probs) -> KrausChannel

Returns a [`KrausChannel`](@ref) instance, where ``operators` is a list of operators, `probs` is a real vector that sum up to 1.
The kraus channel is defined as below

```math
\\phi(\\rho) = \\sum_i p_i U_i ρ U_i^\\dagger,
```

where ``\\rho`` in a [`DensityMatrix`](@ref) as the register to apply on, ``p_i`` is the i-th element in `probs`, `U_i` is the i-th operator in `operators`.

### Examples

```jldoctest; setup=:(using Yao)
julia> kraus_channel([X, Y, Z], [0.1, 0.2, 0.7])
nqubits: 1
kraus_channel
├─ [0.1] X
├─ [0.2] Y
└─ [0.7] Z
```
"""
kraus_channel(operators, probs::AbstractVector) = KrausChannel(operators, probs)


