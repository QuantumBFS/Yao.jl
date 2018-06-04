struct Swap{N, T} <: PrimitiveBlock{N, T}
    line1::UInt
    line2::UInt
end

Swap(::Type{T}, N::Int, addr1, addr2) where T = Swap{N, T}(addr1, addr2)

function mat(g::Swap{N, T}) where {N, T}
end
