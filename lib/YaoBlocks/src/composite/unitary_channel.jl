export UnitaryChannel

# NOTE: this can have a better support in YaoIR directly with StatsBase
# as an compiled instruction, but store the weights is the best solution
# here

"""
    UnitaryChannel{D, W<:AbstractVector} <: CompositeBlock{D}
    UnitaryChannel(operators, weights)

Create a unitary channel, where `weights` is a real vector that sum up to 1.
The unitary channel is defined as below in Kraus representation

```math
ϕ(ρ) = \\sum_i U_i ρ U_i^†
```

### Examples

```jldoctest; setup=:(using Yao)
julia> UnitaryChannel([X, Y, Z], [0.1, 0.2, 0.7])
nqubits: 1
unitary_channel
├─ [0.1] X
├─ [0.2] Y
└─ [0.7] Z
```
"""
struct UnitaryChannel{D, W<:AbstractVector} <: CompositeBlock{D}
    n::Int
    operators::Vector{AbstractBlock{D}}
    weights::W

    function UnitaryChannel(operators::Vector{AbstractBlock{D}}, w::AbstractVector) where D
        @assert length(operators) == length(w) && length(w) != 0
        if !(sum(w) ≈ 1)
            error("The sum of weights must be 1!")
        end
        n = _check_block_sizes(operators)
        new{D,typeof(w)}(n, operators, w)
    end
end

function UnitaryChannel(it, weights)
    length(it) == 0 && error("The input operator list size can not be 0!")
    D = nlevel(first(it))
    UnitaryChannel(collect(AbstractBlock{D}, it), weights)
end
nqudits(uc::UnitaryChannel) = uc.n

function YaoAPI.unsafe_apply!(r::DensityMatrix{D,T}, x::UnitaryChannel) where {D,T}
    r0 = copy(r)
    # first
    regscale!(unsafe_apply!(r, first(x.operators)), first(x.weights))
    for (w, o) in zip(x.weights[2:end-1], x.operators[2:end-1])
        r.state .+= w .* unsafe_apply!(copy(r0), o).state
    end
    # last
    r.state .+= last(x.weights) .* unsafe_apply!(r0, last(x.operators)).state
    return r
end

function mat(::Type{T}, x::UnitaryChannel) where {T}
    error("`UnitaryChannel` does not have a matrix representation!")
end

subblocks(x::UnitaryChannel) = x.operators
chsubblocks(x::UnitaryChannel, it) = UnitaryChannel(collect(it), x.weights)
occupied_locs(x::UnitaryChannel) = union(occupied_locs.(x.operators)...)

function cache_key(x::UnitaryChannel)
    key = hash(x.weights)
    for each in x.operators
        key = hash(each, key)
    end
    return key
end

function Base.:(==)(lhs::UnitaryChannel, rhs::UnitaryChannel)
    return (lhs.n == rhs.n) && (lhs.weights == rhs.weights) && (lhs.operators == rhs.operators)
end

Base.adjoint(x::UnitaryChannel) = UnitaryChannel(adjoint.(x.operators), x.weights)
