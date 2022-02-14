using StatsBase
using YaoArrayRegister
export UnitaryChannel

# TODO: replace this with uweight
# when StatsBase 0.33 is out
_uweights(n) = weights(ones(n))

# NOTE: this can have a better support in YaoIR directly with StatsBase
# as an compiled instruction, but store the weights is the best solution
# here

"""
    UnitaryChannel(operators[, weights])

Create a unitary channel, optionally weighted from an list of weights.
The unitary channel is defined as below in Kraus representation

```math
ϕ(ρ) = \\sum_i U_i ρ U_i^†
```

!!! note
    Unitary channel will only normalize the weights when calculating the matrix form,
    thus you should be careful when you need this condition for other purpose.

!!! note
    when applying a `UnitaryChannel` on the register, a unitary will be sampled
    uniformly or optionally from given weights, then this unitary will be applied
    to the register. 

# Example

```jldoctest; setup=:(using YaoBlocks, YaoArrayRegister)
julia> UnitaryChannel([X, Y, Z])
nqudits: 1
unitary_channel
├─ [1.0] X
├─ [1.0] Y
└─ [1.0] Z
```

Or with weights

```jldoctest; setup=:(using YaoBlocks, YaoArrayRegister)
julia> UnitaryChannel([X, Y, Z], [0.1, 0.2, 0.7])
nqudits: 1
unitary_channel
├─ [0.1] X
├─ [0.2] Y
└─ [0.7] Z
```
"""
struct UnitaryChannel{W<:AbstractWeights} <: CompositeBlock{2}
    n::Int
    operators::Vector{AbstractBlock{2}}
    weights::W

    function UnitaryChannel(operators::Vector)
        w = _uweights(length(operators))
        n = _check_block_sizes(operators)
        new{typeof(w)}(n, operators, w)
    end

    function UnitaryChannel(operators::Vector, w::AbstractWeights)
        n = _check_block_sizes(operators)
        new{typeof(w)}(n, operators, w)
    end

    function UnitaryChannel(operators::Vector, w::AbstractVector)
        w = weights(w)
        n = _check_block_sizes(operators)
        new{typeof(w)}(n, operators, w)
    end
end

UnitaryChannel(it, weights) = UnitaryChannel(collect(it), weights)
UnitaryChannel(it) = UnitaryChannel(collect(it))
nqudits(uc::UnitaryChannel) = uc.n

function _apply!(r::AbstractRegister, x::UnitaryChannel)
    _apply!(r, sample(x.operators, x.weights))
end

function mat(::Type{T}, x::UnitaryChannel) where {T}
    U = sample(x.operators, x.weights)
    return mat(T, U)
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
