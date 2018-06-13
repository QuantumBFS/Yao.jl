export Concentrator

"""
    Concentrator{N} <: AbstractBlock

concentrates serveral lines together in the circuit, and expose
it to other blocks.
"""
struct Concentrator{N, T, BT <: AbstractBlock} <: CompositeBlock{N, T}
    block::BT
    usedbits::Vector{Int}
end
Concentrator{N}(block::BT, usedbits::Vector{Int}) where {N, BT<:AbstractBlock} = Concentrator{N, Bool, BT}(block, usedbits)
function Concentrator{N}(block::BT, usedbits::Vector{Int}) where {N, M, T, BT<:MatrixBlock{M, T}}
    length(usedbits) == M && N>=M || throw(AddressConflictError("length of usedbits must be equal to the size of block, and smaller than size of itself."))
    Concentrator{N, T, BT}(block, usedbits)
end

blocks(c::Concentrator) = [c.block]
nqubits(::Concentrator{N}) where N = N
eltype(::Concentrator{N, T}) where {N, T}= T
nactive(c::Concentrator) = length(c.usedbits)
usedbits(c::Concentrator) = c.usedbits
addrs(c::Concentrator) = [1]

apply!(reg::AbstractRegister, c::Concentrator) = relax!(apply!(focus!(reg, usedbits(c)), c.block), usedbits(c), nbit=nqubits(c))

for FUNC in [:isunitary, :isreflexive, :ishermitian]
    @eval $FUNC(c::Concentrator) = $FUNC(c.block)
end

function print_block(io::IO, c::Concentrator)
    print(io, "Concentrator: ", c.usedbits)
end
