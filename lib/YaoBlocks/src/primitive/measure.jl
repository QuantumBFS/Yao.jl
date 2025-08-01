export Measure,
    MeasureAndReset, AllLocs, ComputationalBasis, chmeasureoperator, num_measured

"""
    Measure{D,K, OT, LT, PT, RNG} <: PrimitiveBlock{D}
    Measure(n::Int; rng=Random.GLOBAL_RNG, operator=ComputationalBasis(), locs=1:n, resetto=nothing, remove=false, nlevel=2, error_prob=0.0)

Measurement block.

### Fields
* `n::Int`: number of qubits.
* `rng::RNG`: random number generator.
* `operator::OT`: operator to measure, by default it is `ComputationalBasis()`.
* `locations::LT`: locations to measure, by default it is `1:n`.
* `postprocess::PT`: postprocess to apply to the measurement result, e.g. `ResetTo` to reset the measured qubits to a specific state.
* `error_prob::Float64`: error probability, by default it is `0.0`. This is only supported for 2-level systems, and the operator must be `ComputationalBasis` or a single qubit operator.
* `results::Any`: measurement results, by default it is `undef`.
"""
mutable struct Measure{D,K,OT,LT<:Union{NTuple{K,Int},AllLocs},PT<:PostProcess,RNG} <:
               PrimitiveBlock{D}
    n::Int
    rng::RNG
    operator::OT
    locations::LT
    postprocess::PT
    error_prob::Float64
    results::Any
    function Measure{D,K,OT,LT,PT,RNG}(n::Int,
        rng::RNG,
        operator::OT,
        locations::LT,
        postprocess::PT,
        error_prob::Float64,
    ) where {RNG,D,K,OT,LT<:Union{NTuple{K,Int},AllLocs},PT<:PostProcess}
        locations isa AllLocs || @assert_locs_safe n locations
        if !(operator isa ComputationalBasis)
            @assert nqudits(operator) == (locations isa AllLocs ? n : length(locations)) "operator size `$(nqudits(operator))` does not match measurement location `$locations`"
        end
        if error_prob > 0.0
            @assert D == 2 "`error_prob` argument is only supported for 2-level systems, got D=$D"
            @assert operator isa ComputationalBasis || nqudits(operator) == 1 "`error_prob` argument is only supported for single qubit operators, got $(typeof(operator))"
        end
        new{D,K,OT,LT,PT,RNG}(n, rng, operator, locations, postprocess, error_prob)
    end
end
nqudits(m::Measure) = m.n

function Measure{D}(n::Int,
    rng::RNG,
    operator::OT,
    locations::LT,
    postprocess::PT,
    error_prob::Float64,
) where {D,RNG,OT,LT<:Union{NTuple{K,Int} where K,AllLocs},PT<:PostProcess}
    k = locations isa AllLocs ? n : length(locations)
    Measure{D,k,OT,LT,PT,RNG}(n, rng, operator, locations, postprocess, error_prob)
end

const MeasureAndReset{D,K,OT,LT,RNG} = Measure{D,K,OT,LT,ResetTo{BitStr64{K}},RNG}
function MeasureAndReset(
    N::Int,
    resetto = 0;
    operator = ComputationalBasis,
    rng = Random.GLOBAL_RNG,
    nlevel=2,
)
    Measure{nlevel}(N; nlevel=nlevel, postprocess = ResetTo(resetto), operator = operator, rng = rng, locs = locs)
end

"""
    chmeasureoperator(m::Measure, op::AbstractBlock)

change the measuring `operator`. It will also discard existing measuring results.
"""
function chmeasureoperator(m::Measure{D}, op::AbstractBlock) where D
    Measure{D}(m.n, m.rng, op, m.locations, m.postprocess, m.error_prob)
end

function Base.:(==)(m1::Measure, m2::Measure)
    res =
        m1.rng == m2.rng &&
        m1.operator == m2.operator &&
        m1.locations == m2.locations &&
        m1.postprocess == m2.postprocess
    res = res && isdefined(m1, :results) == isdefined(m2, :results)
    res && (!isdefined(m1, :results) || m1.results == m2.results)
end

num_measured(::Measure{D,K}) where {D,K} = K

"""
    Measure(n::Int; rng=Random.GLOBAL_RNG, operator=ComputationalBasis(), locs=AllLocs(), resetto=nothing, remove=false, error_prob=0.0)

Create a `Measure` block with number of qudits `n`.

### Examples

You can create a `Measure` block on given basis (default is the computational basis).

```jldoctest; setup=:(using Yao)
julia> Measure(4)
Measure(4)
```

Or you could specify which qudits you are going to measure

```jldoctest; setup=:(using Yao)
julia> Measure(4; locs=1:3)
Measure(4;locs=(1, 2, 3))
```

by default this will collapse the current register to measure results.

```jldoctest; setup=:(using Yao, Random; Random.seed!(123))
julia> r = normalize!(arrayreg(bit"000") + arrayreg(bit"111"))
ArrayReg{2, ComplexF64, Array...}
    active qubits: 3/3
    nlevel: 2

julia> state(r)
8×1 Matrix{ComplexF64}:
 0.7071067811865475 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
 0.7071067811865475 + 0.0im

julia> r |> Measure(3)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 3/3
    nlevel: 2

julia> state(r)
8×1 Matrix{ComplexF64}:
 0.0 + 0.0im
 0.0 + 0.0im
 0.0 + 0.0im
 0.0 + 0.0im
 0.0 + 0.0im
 0.0 + 0.0im
 0.0 + 0.0im
 1.0 + 0.0im
```

But you can also specify the target bit configuration you want to collapse to with keyword `resetto`.

```jldoctest; setup=:(using Yao)
julia> m = Measure(4; resetto=bit"0101")
Measure(4;postprocess=ResetTo{BitStr{4,Int64}}(0101 ₍₂₎))

julia> m.postprocess
ResetTo{BitStr{4,Int64}}(0101 ₍₂₎)```
"""
function Measure(
    n::Int;
    rng::RNG = Random.GLOBAL_RNG,
    operator::OT = ComputationalBasis(),
    locs = AllLocs(),
    resetto = nothing,
    remove = false,
    nlevel = 2,
    error_prob = 0.0,
) where {OT,RNG}
    if resetto !== nothing
        if remove
            error(
                "invalid keyword combination, expect resetto or remove, got (resetto=$resetto, remove=true)",
            )
        else
            postprocess = ResetTo(BitStr64{locs isa AllLocs ? n : length(locs)}(resetto))
        end
    else
        if remove
            postprocess = RemoveMeasured()
        else
            postprocess = NoPostProcess()
        end
    end
    if locs isa AllLocs
        K = n
    else
        locs = (locs...,)
        K = length(locs)
    end
    Measure{nlevel,K,OT,typeof(locs),typeof(postprocess),RNG}(n,rng, operator, locs, postprocess, error_prob)
end

Measure(;
    rng = Random.GLOBAL_RNG,
    locs = AllLocs(),
    operator = ComputationalBasis(),
    resetto = nothing,
    remove = false,
    nlevel = 2,
) = @λ(
    n -> Measure(
        n;
        rng = rng,
        locs = locs,
        operator = operator,
        resetto = resetto,
        remove = remove,
        nlevel = nlevel,
    )
)
mat(x::Measure) = error("use BlockMap to get its matrix.")

function YaoAPI.unsafe_apply!(r::AbstractRegister{D}, m::Measure{D}) where {D}
    m.results = measure!(m.postprocess, m.operator, r, m.locations; rng = m.rng)
    iszero(m.error_prob) && return r
    if m.operator isa ComputationalBasis
        for i in 1:length(m.results)  # try to flip each qubit
            if rand(m.rng) < m.error_prob
                m.results ⊻= 1 << (i-1)
            end
        end
    else   # operators
        E, V = eigenbasis(m.operator)
        evals = diag(mat(E))  # must have exactly 2 eigenvalues
        if rand(m.rng) < m.error_prob  # flip results
            m.results = m.results == evals[1] ? evals[2] : evals[1]
        end
    end
    return r
end

occupied_locs(m::Measure) = m.locations isa AllLocs ? (1:nqudits(m)...,) : m.locations
