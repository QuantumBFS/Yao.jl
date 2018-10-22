export Concentrator

"""
    Concentrator{N, T, BT <: AbstractBlock} <: AbstractContainer{N, T}

concentrates serveral lines together in the circuit, and expose
it to other blocks.
"""
struct Concentrator{N, T, BT <: AbstractBlock} <: AbstractContainer{N, T}
    block::BT
    usedbits::Vector{Int}
end
Concentrator{N}(block::BT, usedbits::Vector{Int}) where {N, BT<:AbstractBlock} = Concentrator{N, Bool, BT}(block, usedbits)
function Concentrator{N}(block::BT, usedbits::Vector{Int}) where {N, M, T, BT<:MatrixBlock{M, T}}
    length(usedbits) == M && N>=M || throw(AddressConflictError("length of usedbits must be equal to the size of block, and smaller than size of itself."))
    Concentrator{N, T, BT}(block, usedbits)
end

nqubits(::Concentrator{N}) where N = N
nactive(c::Concentrator) = length(c.usedbits)
usedbits(c::Concentrator) = c.usedbits
addrs(c::Concentrator) = [1]
chblock(pb::Concentrator{N}, blk::AbstractBlock) where N = Concentrator{N}(blk, pb |> usedbits)
iscommute(x::Concentrator{N}, y::Concentrator{N}) where N = x.usedbits == y.usedbits ? iscommute(x.block, y.block) : _default_iscommute(x, y)

apply!(reg::AbstractRegister, c::Concentrator) = relax!(apply!(focus!(reg, usedbits(c)), c.block), usedbits(c), nbit=nqubits(c))
adjoint(blk::Concentrator{N}) where N = Concentrator{N}(adjoint(blk.block), blk.usedbits)
function mat(c::Concentrator)
    c.block isa MatrixBlock || throw(MethodError(mat, c))
    throw(ArgumentError("It should have a matrix, but we didn't realize it, you can post an issue if you really need it."))
end

istraitkeeper(::Concentrator) = Val(true)

==(a::Concentrator{N, T, BT}, b::Concentrator{N, T, BT}) where {N, T, BT} = a.block == b.block && a.usedbits == b.usedbits

function print_block(io::IO, c::Concentrator)
    print(io, "Concentrator: ", c.usedbits)
end
