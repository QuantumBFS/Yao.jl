using YaoBase
export Concentrator, concentrate

"""
    Concentrator{N, T, BT <: AbstractBlock} <: AbstractContainer{N, T}

concentrates serveral lines together in the circuit, and expose
it to other blocks.
"""
struct Concentrator{N, T, BT <: AbstractBlock, C} <: AbstractContainer{N, T, BT}
    content::BT
    locations::NTuple{C, Int}
end

function Concentrator{N}(block::BT, locations::NTuple{C, Int}) where {N, M, C, T, BT<:AbstractBlock{M, T}}
    if !(length(locations) == M && N>=M)
        throw(LocationConflictError("length of locations must be equal to the size of block, and smaller than size of itself."))
    end
    return Concentrator{N, T, BT, C}(block, locations)
end

"""
    concentrate(n, block, locs)

Create a [`Concentrator`](@ref) block with total number of current active qubits `n`,
which concentrates given wire location together to `length(locs)` active qubits,
and relax the concentration afterwards.
"""
function concentrate(n::Int, block::AbstractBlock, locs)
    return Concentrator{n}(block, Tuple(locs))
end

"""
    concentrate(block, locs) -> f(n)

Lazy curried version of [`concentrate`](@ref).
"""
concentrate(block::AbstractBlock, locs) = @λ(n->concentrate(n, block, locs))

occupied_locs(c::Concentrator) = c.locations
chsubblocks(pb::Concentrator{N}, blk::AbstractBlock) where N =
    Concentrator{N}(blk, occupied_locs(pb))
PreserveStyle(::Concentrator) = PreserveAll()

function apply!(r::AbstractRegister, c::Concentrator)
    focus!(r, occupied_locs(c))
    apply!(r, c.content)
    relax!(r, occupied_locs(c)) # to_nactive=nqubits(r)
    return r
end

mat(c::Concentrator{N, T, <:AbstractBlock}) where {N, T} =
    error("Not implemented, post an issue if you really need it.")

Base.adjoint(blk::Concentrator{N}) where N =
    Concentrator{N}(adjoint(blk.content), occupied_locs(blk))

function Base.:(==)(a::Concentrator{N, T, BT}, b::Concentrator{N, T, BT}) where {N, T, BT}
    return a.content == b.content && a.locations == b.locations
end

YaoBase.nqubits(::Concentrator{N}) where N = N
YaoBase.nactive(c::Concentrator) = length(c.locations)

function YaoBase.iscommute(x::Concentrator{N}, y::Concentrator{N}) where N
    if occupied_locs(x) == occupied_locs(y)
        return iscommute(x.content, y.content)
    else
        return iscommute_fallback(x, y)
    end
end
