export UnitaryChannel, unitary_channel

# NOTE: this can have a better support in YaoIR directly with StatsBase
# as an compiled instruction, but store the probabilities is the best solution
# here

"""
    UnitaryChannel{D, W<:AbstractVector} <: CompositeBlock{D}
    UnitaryChannel(operators, probs)

Create a unitary channel, where `probs` is a real vector that sum up to 1.
"""
struct UnitaryChannel{D, W<:AbstractVector} <: CompositeBlock{D}
    n::Int
    operators::Vector{AbstractBlock{D}}
    probs::W

    function UnitaryChannel(operators::Vector{AbstractBlock{D}}, w::AbstractVector) where D
        @assert length(operators) == length(w) && length(w) != 0
        if !(all(x->x>=0, w) && sum(w) ≈ 1)
            error("The probabilities must be ⩾ 0 and its sum must be 1!")
        end
        n = _check_block_sizes(operators)
        new{D,typeof(w)}(n, operators, w)
    end
end

function UnitaryChannel(it, probs)
    length(it) == 0 && error("The input operator list size can not be 0!")
    D = nlevel(first(it))
    UnitaryChannel(collect(AbstractBlock{D}, it), probs)
end
nqudits(uc::UnitaryChannel) = uc.n

function YaoAPI.unsafe_apply!(r::DensityMatrix{D,T}, x::PutBlock{D,C,<:UnitaryChannel}) where {D,C,T}
    unsafe_apply!(r, UnitaryChannel([PutBlock(x.n, operator, x.locs) for operator in x.content.operators], x.content.probs))
end
function YaoAPI.unsafe_apply!(r::DensityMatrix{D,T}, x::UnitaryChannel) where {D,T}
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

function mat(::Type{T}, x::UnitaryChannel) where {T}
    error("`UnitaryChannel` does not have a matrix representation!")
end

subblocks(x::UnitaryChannel) = x.operators
chsubblocks(x::UnitaryChannel, it) = UnitaryChannel(collect(it), x.probs)
occupied_locs(x::UnitaryChannel) = union(occupied_locs.(x.operators)...)

function cache_key(x::UnitaryChannel)
    key = hash(x.probs)
    for each in x.operators
        key = hash(each, key)
    end
    return key
end

function Base.:(==)(lhs::UnitaryChannel, rhs::UnitaryChannel)
    return (lhs.n == rhs.n) && (lhs.probs == rhs.probs) && (lhs.operators == rhs.operators)
end

Base.adjoint(x::UnitaryChannel) = UnitaryChannel(adjoint.(x.operators), x.probs)

"""
    unitary_channel(operators, probs) -> UnitaryChannel

Returns a [`UnitaryChannel`](@ref) instance, where ``operators` is a list of operators, `probs` is a real vector that sum up to 1.
The unitary channel is defined as below

```math
ϕ(ρ) = \\sum_i p_i U_i ρ U_i^†,
```

where ``ρ`` in a [`DensityMatrix`](@ref) as the register to apply on, ``p_i`` is the i-th element in `probs`, `U_i` is the i-th operator in `operators`.

### Examples

```jldoctest; setup=:(using Yao)
julia> unitary_channel([X, Y, Z], [0.1, 0.2, 0.7])
nqubits: 1
unitary_channel
├─ [0.1] X
├─ [0.2] Y
└─ [0.7] Z
```
"""
unitary_channel(operators, probs::AbstractVector) = UnitaryChannel(operators, probs)
