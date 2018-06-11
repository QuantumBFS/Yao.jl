export Concentrator

"""
    Concentrator{N} <: AbstractBlock

concentrates serveral lines together in the circuit, and expose
it to other blocks.
"""
struct Concentrator{N, T, BT <: AbstractBlock} <: CompositeBlock{N, T}
    block::BT
    address::Vector{Int}
end
Concentrator{N}(block::BT, address::Vector{Int}) where {N, BT<:AbstractBlock} = Concentrator{N, Bool, BT}(block, address)
function Concentrator{N}(block::BT, address::Vector{Int}) where {N, M, T, BT<:MatrixBlock{M, T}}
    length(address) == M && N>=M || throw(ArgumentError("length of address must be equal to the size of block, and smaller than size of itself."))
    Concentrator{N, T, BT}(block, address)
end

blocks(c::Concentrator) = [c.block]
nqubits(::Concentrator{N}) where N = N
eltype(::Concentrator{N, T}) where {N, T}= T
nactive(c::Concentrator) = length(c.address)
address(c::Concentrator) = c.address

apply!(reg::AbstractRegister, c::Concentrator) = relax!(apply!(focus!(reg, address(c)), c.block), address(c), nqubits(c))

for FUNC in [:isunitary, :isreflexive, :ishermitian]
    @eval $FUNC(c::Concentrator) = $FUNC(c.block)
end

function print_block(io::IO, c::Concentrator)
    print(io, "Concentrator: ", c.address)
end
