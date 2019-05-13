using YaoBase, YaoArrayRegister
export Measure, AllLocs, ComputationalBasis

"""
    Measure{N, K, OT} <: PrimitiveBlock{N}
    Measure(n::Int; operator=ComputationalBasis(), locs=1:n, collapseto=nothing, remove=false)

Measure operator.
"""
mutable struct Measure{N, K, OT} <: PrimitiveBlock{N}
    operator::OT
    locations::Union{NTuple{K, Int}, AllLocs}
    collapseto::Union{Int, Nothing}
    remove::Bool
    results::Vector{Int}
    function Measure{N, K, OT}(operator, locations, collapseto, remove) where {N, K, OT}
        locations isa AllLocs || @assert_locs_safe N locations
        if collapseto !== nothing && remove == true
            error("invalid keyword combination, expect collapseto or remove, got (collapseto=$collapseto, remove=true)")
        end
        new{N, K, OT}(operator, locations, collapseto, remove)
    end
end

@interface nqubits_measured(::Measure{N, K}) where {N, K} = K

"""
    Measure(n::Int; operator=ComputationalBasis(), locs=AllLocs(), collapseto=nothing, remove=false)

Create a `Measure` block with number of qubits `n`.

# Example

You can create a `Measure` block on given basis (default is the computational basis).

```jldoctest
julia> Measure(4)
Measure(4)
```

Or you could specify which qubits you are going to measure

```jldoctest
julia> Measure(4; locs=1:3)
Measure(4; locs=(1, 2, 3))
```

by default this will collapse the current register to measure results.

```julia
julia> r = rand_state(3)
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 3/3

julia> state(r)
8×1 Array{Complex{Float64},2}:
  0.19864933724343375 - 0.4740335956912438im
  -0.2057912765333517 - 0.2262668486124923im
 -0.41680007712245676 - 0.13759187422609387im
 -0.24336704548326407 + 0.27343538360398184im
 -0.09308092255704317 - 0.005308959093704435im
  0.24555464152683212 + 0.02737969837364506im
  -0.3828287267256825 + 0.02401578941643196im
 0.048647936794205926 + 0.31047610497928607im

julia> r |> Measure(3)
Measure(3)

julia> state(r)
8×1 Array{Complex{Float64},2}:
                 0.0 + 0.0im
                 0.0 + 0.0im
 -0.9495962023170939 - 0.31347576069762273im
                 0.0 + 0.0im
                 0.0 + 0.0im
                 0.0 + 0.0im
                 0.0 + 0.0im
                 0.0 + 0.0im
```

But you can also specify the target bit configuration you want to collapse to with keyword `collapseto`.

```jldoctest
julia> Measure(4; collapseto=0b101)
Measure(4;collapseto=5)

julia> m.collapseto
5
```
"""
function Measure(n::Int; operator::OT=ComputationalBasis(), locs=AllLocs(), collapseto=nothing, remove=false) where OT
    if locs isa AllLocs
        Measure{n, n, OT}(operator, locs, collapseto, remove)
    else
        Measure{n, length(locs), OT}(operator, tuple(locs...), collapseto, remove)
    end
end

Measure(;locs=AllLocs(), operator=ComputationalBasis(), collapseto=nothing, remove=false) where K = @λ(n->Measure(n; locs=locs, operator=operator, collapseto=collapseto, remove=remove))
mat(x::Measure) = error("use BlockMap to get its matrix.")

function apply!(r::AbstractRegister, m::Measure{N}) where {N}
    _check_size(r, m)
    if m.collapseto !== nothing
        m.results = measure_collapseto!(m.operator, r, m.locations; config=m.collapseto)
    elseif m.remove
        m.results = measure_remove!(m.operator, r, m.locations)
    else
        m.results = measure!(m.operator, r, m.locations)
    end
    return m
end
