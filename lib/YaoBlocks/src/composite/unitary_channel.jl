using StatsBase
using YaoArrayRegister
export UnitaryChannel

# TODO: replace this with uweight
# when StatsBase 0.33 is out
_uweights(n) = weights(ones(n))

function check_nqudits(operators)
    N = nqudits(first(operators))
    for each in operators
        N == nqudits(each) || throw(AssertionError("number of qubits mismatch"))
    end
    return N
end

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
struct UnitaryChannel{N,W<:AbstractWeights} <: CompositeBlock{N,2}
    operators::Vector{AbstractBlock{N}}
    weights::W

    function UnitaryChannel(operators::Vector)
        w = _uweights(length(operators))
        N = check_nqudits(operators)
        new{N,typeof(w)}(operators, w)
    end

    function UnitaryChannel(operators::Vector, w::AbstractWeights)
        N = check_nqudits(operators)
        new{N,typeof(w)}(operators, w)
    end

    function UnitaryChannel(operators::Vector, w::AbstractVector)
        w = weights(w)
        N = check_nqudits(operators)
        new{N,typeof(w)}(operators, w)
    end
end

UnitaryChannel(it, weights) = UnitaryChannel(collect(it), weights)
UnitaryChannel(it) = UnitaryChannel(collect(it))

function _apply!(r::AbstractRegister, x::UnitaryChannel)
    _apply!(r, sample(x.operators, x.weights))
end

function mat(::Type{T}, x::UnitaryChannel) where {T}
    U = sample(x.operators, x.weights)
    return mat(T, U)
end

subblocks(x::UnitaryChannel) = x.operators
chsubblocks(x::UnitaryChannel{N}, it) where {N} = UnitaryChannel{N}(collect(it), x.weights)
occupied_locs(x::UnitaryChannel) = union(occupied_locs.(x.operators)...)

function cache_key(x::UnitaryChannel)
    key = hash(x.weights)
    for each in x.operators
        key = hash(each, key)
    end
    return key
end

function Base.:(==)(lhs::UnitaryChannel{N}, rhs::UnitaryChannel{N}) where {N}
    return (lhs.weights == rhs.weights) && (lhs.operators == rhs.operators)
end

Base.adjoint(x::UnitaryChannel) = UnitaryChannel(adjoint.(x.operators), x.weights)
