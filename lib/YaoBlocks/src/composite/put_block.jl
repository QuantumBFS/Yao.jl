using StatsBase
export PutBlock, put, Swap, swap, PSwap, pswap

"""
    PutBlock <: AbstractContainer

Type for putting a block at given locations.
"""
struct PutBlock{N,C,GT<:AbstractBlock} <: AbstractContainer{GT,N}
    content::GT
    locs::NTuple{C,Int}

    function PutBlock{N}(block::GT, locs::NTuple{C,Int}) where {N,M,C,GT<:AbstractBlock{M}}
        @assert_locs_safe N locs
        @assert nqubits(block) == C "number of locations doesn't match the size of block"
        return new{N,C,GT}(block, locs)
    end
end

"""
    put(total::Int, pair)

Create a [`PutBlock`](@ref) with total number of active qubits, and a pair of
location and block to put on.

# Example

```jldoctest; setup=:(using YaoBlocks)
julia> put(4, 1=>X)
nqubits: 4
put on (1)
└─ X
```

If you want to put a multi-qubit gate on specific locations, you need to write down all possible locations.

```jldoctest; setup=:(using YaoBlocks)
julia> put(4, (1, 3)=>kron(X, Y))
nqubits: 4
put on (1, 3)
└─ kron
   ├─ 1=>X
   └─ 2=>Y
```

The outter locations creates a scope which make it seems to be a contiguous two qubits for the block inside `PutBlock`.

!!! tips
    It is better to use [`subroutine`](@ref) instead of `put` for large blocks, since put will use the matrix of its contents
    directly instead of making use of what's in it. `put` is more efficient for small blocks.
"""
put(total::Int, pa::Pair{NTuple{M,Int},<:AbstractBlock}) where {M} =
    PutBlock{total}(pa.second, pa.first)
put(total::Int, pa::Pair{Int,<:AbstractBlock}) = PutBlock{total}(pa.second, (pa.first,))
put(total::Int, pa::Pair{<:Any,<:AbstractBlock}) =
    PutBlock{total}(pa.second, Tuple(pa.first))

"""
    put(pair) -> f(n)

Lazy curried version of [`put`](@ref).

# Example

```jldoctest; setup=:(using YaoBlocks)
julia> put(1=>X)
(n -> put(n, 1 => X))
```
"""
put(pa::Pair) = @λ(n -> put(n, pa))

occupied_locs(x::PutBlock) = map(i -> x.locs[i], x.content |> occupied_locs)
chsubblocks(x::PutBlock{N}, b::AbstractBlock) where {N} = PutBlock{N}(b, x.locs)
PropertyTrait(::PutBlock) = PreserveAll()
cache_key(pb::PutBlock) = cache_key(pb.content)

mat(::Type{T}, pb::PutBlock{N,1}) where {T,N} = u1mat(N, mat(T, pb.content), pb.locs...)
mat(::Type{T}, pb::PutBlock{N,C}) where {T,N,C} = unmat(N, mat(T, pb.content), pb.locs)

function _apply!(r::AbstractRegister, pb::PutBlock{N}) where {N}
    instruct!(r, mat_matchreg(r, pb.content), pb.locs)
    return r
end

# NOTE: Roger: these specialization should be removed after the new interpret
# mechanism is implemented
# specialization
for G in [:X, :Y, :Z, :T, :S, :Sdag, :Tdag, :H]
    GT = Expr(:(.), :ConstGate, QuoteNode(Symbol(G, :Gate)))
    @eval function _apply!(r::AbstractRegister, pb::PutBlock{N,C,<:$GT}) where {N,C}
        instruct!(r, Val($(QuoteNode(G))), pb.locs)
        return r
    end
end

Base.adjoint(x::PutBlock{N}) where {N} = PutBlock{N}(adjoint(content(x)), x.locs)
Base.copy(x::PutBlock{N}) where {N} = PutBlock{N}(x.content, x.locs)
function Base.:(==)(lhs::PutBlock{N,C,GT}, rhs::PutBlock{N,C,GT}) where {N,C,GT}
    return (lhs.content == rhs.content) && (lhs.locs == rhs.locs)
end

function YaoBase.iscommute(x::PutBlock{N}, y::PutBlock{N}) where {N}
    if x.locs == y.locs
        return iscommute(x.content, y.content)
    else
        return iscommute_fallback(x, y)
    end
end

const Swap{N} = PutBlock{N,2,G} where {G<:ConstGate.SWAPGate}
const PSwap{N,T} = PutBlock{N,2,RotationGate{2,T,G}} where {G<:ConstGate.SWAPGate}
Swap{N}(locs::Tuple{Int,Int}) where {N} = PutBlock{N}(ConstGate.SWAPGate(), locs)
PSwap{N}(locs::Tuple{Int,Int}, θ::Real) where {N} =
    PutBlock{N}(rot(ConstGate.SWAPGate(), θ), locs)

"""
    swap(n, loc1, loc2)

Create a `n`-qubit [`Swap`](@ref) gate which swap `loc1` and `loc2`.

# Example

```jldoctest; setup=:(using YaoBlocks)
julia> swap(4, 1, 2)
nqubits: 4
put on (1, 2)
└─ SWAP
```
"""
swap(n::Int, loc1::Int, loc2::Int) = Swap{n}((loc1, loc2))

"""
    swap(loc1, loc2) -> f(n)

Create a lambda that takes the total number of active qubits as input. Lazy curried
version of `swap(n, loc1, loc2)`. See also [`Swap`](@ref).

# Example

```jldoctest; setup=:(using YaoBlocks)
julia> swap(1, 2)
(n -> swap(n, 1, 2))
```
"""
swap(loc1::Int, loc2::Int) = @λ(n -> swap(n, loc1, loc2))

function mat(::Type{T}, g::Swap{N}) where {T,N}
    mask = bmask(g.locs[1], g.locs[2])
    orders = map(b -> swapbits(b, mask) + 1, basis(N))
    return PermMatrix(orders, ones(T, 1 << N))
end

_apply!(r::AbstractRegister, g::Swap) = (instruct!(r, Val(:SWAP), g.locs); r)
occupied_locs(g::Swap) = g.locs

"""
    pswap(n::Int, i::Int, j::Int, α::Real)
    pswap(i::Int, j::Int, α::Real) -> f(n)

parametrized swap gate.
"""
pswap(n::Int, i::Int, j::Int, α::Real) = PSwap{n}((i, j), α)
pswap(i::Int, j::Int, α::Real) = n -> pswap(n, i, j, α)

for (G, GT) in [
    (:Rx, :(PutBlock{N,1,RotationGate{1,T,XGate}} where {N,T})),
    (:Ry, :(PutBlock{N,1,RotationGate{1,T,YGate}} where {N,T})),
    (:Rz, :(PutBlock{N,1,RotationGate{1,T,ZGate}} where {N,T})),
    (:PSWAP, :(PSwap)),
]
    @eval function _apply!(reg::AbstractRegister, g::$GT)
        instruct!(reg, Val($(QuoteNode(G))), g.locs, g.content.theta)
        return reg
    end
end
