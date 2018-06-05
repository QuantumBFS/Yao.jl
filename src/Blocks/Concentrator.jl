export Concentrator

"""
    Concentrator{<:Union{Int, Tuple}} <: AbstractBlock

concentrates serveral lines together in the circuit, and expose
it to other blocks.
"""
struct Concentrator{T <: Union{Int, Tuple}} <: AbstractBlock
    address::T
end

Concentrator(orders...) = Concentrator(orders)

eltype(::Concentrator) = Bool
isunitary(x::Concentrator) = true
nqubits(x::Concentrator) = ninput(x)
ninput(x::Concentrator) = GreaterThan{length(x.address)}
noutput(x::Concentrator) = length(x.address)
address(x::Concentrator) = x.address

apply!(reg::AbstractRegister, block::Concentrator) = focus!(reg, address(block)...)

function show(io::IO, block::Concentrator)
    print(io, "Concentrator: ", block.address)
end
