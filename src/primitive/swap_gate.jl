using YaoBase, BitBasis
using YaoArrayRegister: swaprows!

export Swap, swap

struct Swap{N, T} <: PrimitiveBlock{N, T}
    locs::Tuple{Int, Int}

    function Swap{N, T}(locs::Tuple{Int, Int}) where {N, T}
        @assert_locs N locs
        return new{N, T}(locs)
    end
end

Swap{N, T}(loc1::Int, loc2::Int) where {N, T} = Swap{N, T}((loc1, loc2))


swap(::Type{T}, n::Int, loc1::Int, loc2::Int) where T = Swap{n, T}((loc1, loc2))

"""
    swap([T=ComplexF64], n, loc1, loc2)

Return a `n`-qubit [`Swap`](@ref) gate which swap `loc1` and `loc2`.
"""
swap(n::Int, loc1::Int, loc2::Int) = swap(ComplexF64, n, loc1, loc2)

"""
    swap(loc1, loc2) -> f(n)

Return a lambda that takes the total number of active qubits as input. See also
[`swap`](@ref), [`Swap`](@ref).
"""
swap(loc1::Int, loc2::Int) = @λ(n -> swap(n, loc1, loc2))

function mat(g::Swap{N, T}) where {N, T}
    mask = bmask(g.locs[1], g.locs[2])
    orders = map(b->swapbits(b, mask) + 1, basis(N))
    return PermMatrix(orders, ones(T, 1<<N))
end

apply!(r::ArrayReg, g::Swap) = instruct!(state(r), Val(:SWAP), g.locs)
occupied_locs(g::Swap) = g.locs

Base.:(==)(lhs::Swap, rhs::Swap) = lhs.locs == rhs.locs

YaoBase.isunitary(rb::Swap) = true
YaoBase.ishermitian(rb::Swap) = true
YaoBase.isreflexive(rb::Swap) = true
