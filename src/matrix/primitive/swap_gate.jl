export Swap

using YaoArrayRegister: swaprows!

struct Swap{N, T} <: PrimitiveBlock{N, T}
    locs::Tuple{Int, Int}

    function Swap{N, T}(locs::Tuple{Int, Int}) where {N, T}
        @assert_addrs_inbounds N locs
        return new{N, T}(locs)
    end
end

Swap{N, T}(loc1::Int, loc2::Int) where {N, T} = Swap{N, T}((loc1, loc2))

function mat(g::Swap{N, T}) where {N, T}
    mask = bmask(g.locs[1], g.locs[2])
    orders = map(b->swapbits(b, mask) + 1, basis(N))
    return PermMatrix(orders, ones(T, 1<<N))
end

apply!(r::ArrayReg, g::Swap) = instruct!(state(r), Val(:SWAP), g.locs)
occupied_locations(g::Swap) = g.locs

print_block(io::IO, swap::Swap) =
    printstyled(io, "swap", swap.locs; bold=true, color=color(Swap))


Base.hash(swap::Swap, h::UInt) = hash(swap.locs, h)
Base.:(==)(lhs::Swap, rhs::Swap) = lhs.locs == rhs.locs

YaoBase.isunitary(rb::Swap) = true
YaoBase.ishermitian(rb::Swap) = true
YaoBase.isreflexive(rb::Swap) = true
