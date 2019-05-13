using YaoBase, BitBasis
using YaoArrayRegister: swaprows!

export Swap, swap

"""
    Swap{N, T} <: PrimitiveBlock{N, T}

Swap block, which will swap two locations given.
"""
struct Swap{N} <: PrimitiveBlock{N}
    locs::Tuple{Int, Int}

    function Swap{N}(locs::Tuple{Int, Int}) where N
        @assert_locs_safe N locs
        return new{N}(locs)
    end
end

Swap{N}(loc1::Int, loc2::Int) where N = Swap{N}((loc1, loc2))

"""
    swap(n, loc1, loc2)

Create a `n`-qubit [`Swap`](@ref) gate which swap `loc1` and `loc2`.

# Example

```jldoctest
julia> swap(4, 1, 2)
swap(1, 2)
```
"""
swap(n::Int, loc1::Int, loc2::Int) = Swap{n}((loc1, loc2))

"""
    swap(loc1, loc2) -> f(n)

Create a lambda that takes the total number of active qubits as input. Lazy curried
version of `swap(n, loc1, loc2)`. See also [`Swap`](@ref).

# Example

```jldoctest
julia> swap(1, 2)
(n -> swap(n, 1, 2))
```
"""
swap(loc1::Int, loc2::Int) = @λ(n -> swap(n, loc1, loc2))

function mat(::Type{T}, g::Swap{N}) where {T, N}
    mask = bmask(g.locs[1], g.locs[2])
    orders = map(b->swapbits(b, mask) + 1, basis(N))
    return PermMatrix(orders, ones(T, 1<<N))
end

apply!(r::ArrayReg, g::Swap) = (instruct!(state(r), Val(:SWAP), g.locs); r)
occupied_locs(g::Swap) = g.locs

Base.:(==)(lhs::Swap, rhs::Swap) = lhs.locs == rhs.locs

YaoBase.isunitary(rb::Swap) = true
YaoBase.ishermitian(rb::Swap) = true
YaoBase.isreflexive(rb::Swap) = true
