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
Concentrator{N}(block::BT, address::Vector{Int}) where {N, M, T, BT<:MatrixBlock{M, T}} = Concentrator{N, T, BT}(block, address)

blocks(c::Concentrator) = [c.block]
#nqubits(::Type{MT}) where {N, BT, MT<:Concentrator{N, BT}} = N
nqubits(::Concentrator{N}) where N = N
eltype(::Concentrator{N, T}) where {N, T}= T
nfocus(c::Concentrator) = length(c.address)
address(c::Concentrator) = c.address

apply!(reg::AbstractRegister, c::Concentrator) = relax!(apply!(focus!(reg, address(c)), c.block), address(c), nqubits(c))

for FUNC in [:isunitary, :isreflexive, :ishermitian]
    @eval $FUNC(c::Concentrator) = $FUNC(c.block)
end

function show(io::IO, c::Concentrator)
    print(io, "Concentrator: ", c.address)
end
