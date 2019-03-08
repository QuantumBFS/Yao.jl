using YaoBase
export Concentrator, concentrate

"""
    Concentrator{N, T, BT <: AbstractBlock} <: AbstractContainer{N, T}

concentrates serveral lines together in the circuit, and expose
it to other blocks.
"""
struct Concentrator{N, T, BT <: AbstractBlock, C} <: AbstractContainer{N, T}
    block::BT
    locations::NTuple{C, Int}
end
Concentrator{N}(block::AbstractBlock, locations::NTuple{C, Int}) where {N, C} =
    Concentrator{N, datatype(block), typeof(block), C}(block, locations)

function Concentrator{N}(block::BT, locations::NTuple{C, Int}) where {N, M, C, T, BT<:MatrixBlock{M, T}}
    if !(length(locations) == M && N>=M)
        throw(AddressConflictError("length of locations must be equal to the size of block, and smaller than size of itself."))
    end
    return Concentrator{N, T, BT, C}(block, locations)
end

"""
    concentrate(n, block, addrs)

Create a [`Concentrator`](@ref) block with total number of current active qubits `n`,
which concentrates given wire address together to `length(addrs)` active qubits,
and relax the concentration afterwards.
"""
function concentrate(n::Int, block::AbstractBlock, addrs)
    return Concentrator{n}(block, Tuple(addrs))
end

"""
    concentrate(block, addrs) -> f(n)

Lazy curried version of [`concentrate`](@ref).
"""
concentrate(block::AbstractBlock, addrs) = @λ(n->concentrate(n, block, addrs))

occupied_locations(c::Concentrator) = c.locations
chcontained_block(pb::Concentrator{N}, blk::AbstractBlock) where N =
    Concentrator{N}(blk, occupied_locations(pb))
PreserveStyle(::Concentrator) = PreserveAll()

function apply!(r::AbstractRegister, c::Concentrator)
    focus!(r, occupied_locations(c))
    apply!(r, c.block)
    relax!(r, occupied_locations(c)) # to_nactive=nqubits(r)
    return r
end

mat(c::Concentrator{N, T, <:MatrixBlock}) where {N, T} =
    error("Not implemented, post an issue if you really need it.")

Base.adjoint(blk::Concentrator{N}) where N =
    Concentrator{N}(adjoint(blk.block), occupied_locations(blk))

function Base.:(==)(a::Concentrator{N, T, BT}, b::Concentrator{N, T, BT}) where {N, T, BT}
    return a.block == b.block && a.locations == b.locations
end

YaoBase.nqubits(::Concentrator{N}) where N = N
YaoBase.nactive(c::Concentrator) = length(c.locations)

function YaoBase.iscommute(x::Concentrator{N}, y::Concentrator{N}) where N
    if occupied_locations(x) == occupied_locations(y)
        return iscommute(x.block, y.block)
    else
        return iscommute_fallback(x, y)
    end
end
