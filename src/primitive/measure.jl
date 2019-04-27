using YaoBase, YaoArrayRegister
export Measure

"""
    Measure{N, K, OT} <: PrimitiveBlock{N, Bool}
    Measure(n::Int; operator=ComputationalBasis(), locs=1:n, collapseto=nothing, remove=false)

Measure operator.
"""
mutable struct Measure{N, K, OT} <: PrimitiveBlock{N, Bool}
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

function Measure(n::Int; operator::OT=ComputationalBasis(), locs, collapseto=nothing, remove=false) where OT
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
