using YaoBase, YaoArrayRegister, Random
export Measure, AllLocs, ComputationalBasis, chmeasureoperator

"""
    Measure{N, K, OT, RNG} <: PrimitiveBlock{N}
    Measure(n::Int; rng=Random.GLOBAL_RNG, operator=ComputationalBasis(), locs=1:n, collapseto=nothing, remove=false)

Measure operator.
"""
mutable struct Measure{N, K, OT, RNG} <: PrimitiveBlock{N}
    rng::RNG
    operator::OT
    locations::Union{NTuple{K, Int}, AllLocs}
    collapseto::Union{BitStr64{N}, Nothing}
    remove::Bool
    results::Vector{Int}
    function Measure{N, K, OT, RNG}(rng::RNG, operator, locations, collapseto, remove) where {RNG, N, K, OT}
        locations isa AllLocs || @assert_locs_safe N locations
        if collapseto !== nothing && remove == true
            error("invalid keyword combination, expect collapseto or remove, got (collapseto=$collapseto, remove=true)")
        end
        new{N, K, OT, RNG}(rng, operator, locations, collapseto, remove)
    end
end

"""
    chmeasureoperator(m::Measure, op::AbstractBlock)

change the measuring `operator`. It will also discard existing measuring results.
"""
function chmeasureoperator(m::Measure{N}, op::AbstractBlock) where N
    Measure(N; rng=m.rng, operator=op, locs=m.locations, collapseto=m.collapseto, remove=m.remove)
end

function Base.:(==)(m1::Measure, m2::Measure)
    res = m1.rng == m2.rng && m1.operator == m2.operator &&
    m1.locations == m2.locations && m1.collapseto == m2.collapseto &&
    m1.remove == m2.remove
    res = res && isdefined(m1, :results) == isdefined(m2, :results)
    res && (!isdefined(m1, :results) || m1.results == m2.results)
end

@interface nqubits_measured(::Measure{N, K}) where {N, K} = K

"""
    Measure(n::Int; rng=Random.GLOBAL_RNG, operator=ComputationalBasis(), locs=AllLocs(), collapseto=nothing, remove=false)

Create a `Measure` block with number of qubits `n`.

# Example

You can create a `Measure` block on given basis (default is the computational basis).

```jldoctest; setup=:(using YaoBlocks)
julia> Measure(4)
Measure(4)
```

Or you could specify which qubits you are going to measure

```jldoctest; setup=:(using YaoBlocks)
julia> Measure(4; locs=1:3)
Measure(4;locs=(1, 2, 3))
```

by default this will collapse the current register to measure results.

```jldoctest; setup=:(using YaoBlocks, YaoArrayRegister, BitBasis, Random; Random.seed!(2))
julia> r = rand_state(3)
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 3/3

julia> state(r)
8×1 Array{Complex{Float64},2}:
    0.21633342515406265 - 0.21776267239802458im
   -0.17798384008375148 - 0.5040979387214165im
   -0.19761243345925425 + 0.16281482444784728im
   -0.25200691415025867 + 0.15153595884416518im
     0.3650977378140692 + 0.3419566592091794im
  -0.027207023333497483 - 0.3780181361735894im
 -0.0034728372576413743 + 0.1693915490059622im
   -0.19898587237095824 - 0.07607057769761456im

julia> r |> Measure(3)
Measure(3)

julia> state(r)
8×1 Array{Complex{Float64},2}:
                0.0 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
 0.7298587746534583 + 0.6835979586433478im
                0.0 + 0.0im
                0.0 + 0.0im
                0.0 + 0.0im
```

But you can also specify the target bit configuration you want to collapse to with keyword `collapseto`.

```jldoctest; setup=:(using YaoBlocks; using BitBasis)
julia> m = Measure(4; collapseto=bit"0101")
Measure(4;collapseto=0101 ₍₂₎)

julia> m.collapseto
0101 ₍₂₎
```
"""
function Measure(n::Int; rng::RNG=Random.GLOBAL_RNG, operator::OT=ComputationalBasis(), locs=AllLocs(), collapseto=nothing, remove=false) where {OT, RNG}
    if locs isa AllLocs
        Measure{n, n, OT, RNG}(rng, operator, locs, collapseto, remove)
    else
        Measure{n, length(locs), OT, RNG}(rng, operator, tuple(locs...), collapseto, remove)
    end
end

Measure(;rng=Random.GLOBAL_RNG, locs=AllLocs(), operator=ComputationalBasis(), collapseto=nothing, remove=false) where K = @λ(n->Measure(n; rng=rng, locs=locs, operator=operator, collapseto=collapseto, remove=remove))
mat(x::Measure) = error("use BlockMap to get its matrix.")

function apply!(r::AbstractRegister, m::Measure{N}) where {N}
    _check_size(r, m)
    if m.collapseto !== nothing
        m.results = measure_collapseto!(m.rng, m.operator, r, m.locations; config=m.collapseto)
    elseif m.remove
        m.results = measure_remove!(m.rng, m.operator, r, m.locations)
    else
        m.results = measure!(m.rng, m.operator, r, m.locations)
    end
    return m
end
