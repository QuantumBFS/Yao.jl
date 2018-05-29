struct Swap{N, T} <: PrimitiveBlock{N, T}
    addr1::UInt
    addr2::UInt
end

Swap(::Type{T}, N::Int, addr1, addr2) where T = Swap{N, T}(addr1, addr2)

function sparse(g::Swap{N, T}) where {N, T}
end

# NOTE: this should not be matrix multiplication based
function apply!(r::Register, g::Swap)
end
