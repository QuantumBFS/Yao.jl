using StatsBase
using YaoArrayRegister
export UnitaryChannel

# TODO: replace this with uweight
# when StatsBase 0.33 is out
_uweights(n) = weights(ones(n))

function check_nqubits(operators)
    N = nqubits(first(operators))
    for each in operators
        N == nqubits(each) || throw(AssertionError("number of qubits mismatch"))
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

```jldoctest
julia> UnitaryChannel([X, Y, Z])
nqubits: 1
unitary_channel
├─ [1.0] X gate
├─ [1.0] Y gate
└─ [1.0] Z gate
```

Or with weights

```jldoctest
julia> UnitaryChannel([X, Y, Z], [0.1, 0.2, 0.7])
nqubits: 1
unitary_channel
├─ [0.1] X gate
├─ [0.2] Y gate
└─ [0.7] Z gate
```
"""
struct UnitaryChannel{N, W <: AbstractWeights} <: CompositeBlock{N}
    operators::Vector{AbstractBlock{N}}
    weights::W

    function UnitaryChannel(operators::Vector)
        w = _uweights(length(operators))
        N = check_nqubits(operators)
        new{N, typeof(w)}(operators, w)
    end

    function UnitaryChannel(operators::Vector, w::AbstractWeights)
        N = check_nqubits(operators)
        new{N, typeof(w)}(operators, w)
    end

    function UnitaryChannel(operators::Vector, w::AbstractVector)
        w = weights(w)
        N = check_nqubits(operators)
        new{N, typeof(w)}(operators, w)
    end
end

UnitaryChannel(it, weights) = UnitaryChannel(collect(it), weights)
UnitaryChannel(it) = UnitaryChannel(collect(it))

function apply!(r::AbstractRegister, x::UnitaryChannel)
    apply!(r, sample(x.operators, x.weights))
end

# unitary channel
function apply!(r::AbstractRegister, pb::PutBlock{N, C, <:UnitaryChannel}) where {N, C}
    _check_size(r, pb)
    x = pb.content
    U = sample(x.operators, x.weights)
    apply!(r, PutBlock{N}(U, pb.locs))
    return r
end


function mat(::Type{T}, x::UnitaryChannel) where T
    error("unitary channel can not have a matrix")
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

function Base.:(==)(lhs::UnitaryChannel{N}, rhs::UnitaryChannel{N}) where N
    return (lhs.weights == rhs.weights) && (lhs.operators == rhs.operators)
end

Base.adjoint(x::UnitaryChannel) = UnitaryChannel(adjoint.(x.operators), x.weights)
