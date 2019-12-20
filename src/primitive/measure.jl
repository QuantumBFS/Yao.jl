using YaoBase, YaoArrayRegister, Random
using BitBasis
export Measure, MeasureAndReset, AllLocs, ComputationalBasis, chmeasureoperator

"""
    Measure{N, K, OT, LT, PT, RNG} <: PrimitiveBlock{N}
    Measure(n::Int; rng=Random.GLOBAL_RNG, operator=ComputationalBasis(), locs=1:n, resetto=nothing, remove=false)

Measure operator.
"""
mutable struct Measure{N,K,OT,LT<:Union{NTuple{K,Int},AllLocs},PT<:PostProcess,RNG} <:
               PrimitiveBlock{N}
    rng::RNG
    operator::OT
    locations::LT
    postprocess::PT
    results
    function Measure{N,K,OT,LT,PT,RNG}(
        rng::RNG,
        operator::OT,
        locations::LT,
        postprocess::PT,
    ) where {RNG,N,K,OT,LT<:Union{NTuple{K,Int},AllLocs},PT<:PostProcess}
        locations isa AllLocs || @assert_locs_safe N locations
        new{N,K,OT,LT,PT,RNG}(rng, operator, locations, postprocess)
    end
end

function Measure{N}(
    rng::RNG,
    operator::OT,
    locations::LT,
    postprocess::PT,
) where {RNG,N,OT,LT<:Union{NTuple{K,Int} where K,AllLocs},PT<:PostProcess}
    k = locations isa AllLocs ? N : length(locations)
    Measure{N,k,OT,LT,PT,RNG}(rng, operator, locations, postprocess)
end

const MeasureAndReset{N,K,OT,LT,RNG} = Measure{N,K,OT,LT,ResetTo{BitStr64{K}},RNG}
function MeasureAndReset(N, resetto = 0; operator = ComputationalBasis, rng = Random.GLOBAL_RNG)
    Measure(N; postprocess = ResetTo(resetto), operator = operator, rng = rng, locs = locs)
end

"""
    chmeasureoperator(m::Measure, op::AbstractBlock)

change the measuring `operator`. It will also discard existing measuring results.
"""
function chmeasureoperator(m::Measure{N}, op::AbstractBlock) where {N}
    Measure{N}(m.rng, op, m.locations, m.postprocess)
end

function Base.:(==)(m1::Measure, m2::Measure)
    res =
        m1.rng == m2.rng &&
        m1.operator == m2.operator && m1.locations == m2.locations && m1.postprocess == m2.postprocess
    res = res && isdefined(m1, :results) == isdefined(m2, :results)
    res && (!isdefined(m1, :results) || m1.results == m2.results)
end

@interface nqubits_measured(::Measure{N,K}) where {N,K} = K

"""
    Measure(n::Int; rng=Random.GLOBAL_RNG, operator=ComputationalBasis(), locs=AllLocs(), resetto=nothing, remove=false)

Create a `Measure` block with number of qubits `n`.

# Example

You can create a `Measure` block on given basis (default is the computational basis).

```jldoctest; setup=:(using YaoBlocks)
julia> Measure(4)
Measure(4;postprocess=NoPostProcess())
```

Or you could specify which qubits you are going to measure

```jldoctest; setup=:(using YaoBlocks)
julia> Measure(4; locs=1:3)
Measure(4;locs=(1, 2, 3), postprocess=NoPostProcess())
```

by default this will collapse the current register to measure results.

```jldoctest; setup=:(using YaoBlocks, YaoArrayRegister)
julia> r = normalize!(ArrayReg(bit"000") + ArrayReg(bit"111"))
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 3/3

julia> state(r)
8×1 Array{Complex{Float64},2}:
 0.7071067811865475 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
 0.7071067811865475 + 0.0im

julia> r |> Measure(3)
Measure(3;postprocess=NoPostProcess())

julia> state(r)
1×1 Array{Complex{Float64},2}:
 1.0 + 0.0im
```

But you can also specify the target bit configuration you want to collapse to with keyword `resetto`.

```jldoctest; setup=:(using YaoBlocks; using BitBasis)
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
) where {OT,LT,RNG}
    if resetto !== nothing
        if remove
            error("invalid keyword combination, expect resetto or remove, got (resetto=$resetto, remove=true)")
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
    Measure{n,K,OT,typeof(locs),typeof(postprocess),RNG}(rng, operator, locs, postprocess)
end

Measure(;
    rng = Random.GLOBAL_RNG,
    locs = AllLocs(),
    operator = ComputationalBasis(),
    resetto = nothing,
    remove = false,
) where {K} = @λ(
    n -> Measure(n; rng = rng,
        locs = locs,
        operator = operator,
        resetto = resetto,
        remove = remove)
)
mat(x::Measure) = error("use BlockMap to get its matrix.")

function apply!(r::AbstractRegister, m::Measure{N}) where {N}
    _check_size(r, m)
    m.results = measure!(m.postprocess, m.operator, r, m.locations; rng = m.rng)
    return m
end
