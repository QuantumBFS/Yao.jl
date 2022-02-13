using YaoBase
export Subroutine, subroutine

"""
    Subroutine{N, D, BT <: AbstractBlock, C} <: AbstractContainer{BT, N, D}

Subroutine node on given locations. This allows you to shoehorn a smaller
circuit to a larger one.
"""
struct Subroutine{N,D,BT<:AbstractBlock,C} <: AbstractContainer{BT,N,D}
    content::BT
    locs::NTuple{C,Int}
end

function Subroutine{N}(block::BT, locs::NTuple{C,Int}) where {N,D,M,C,BT<:AbstractBlock{M,D}}
    if !(length(locs) == M && N >= M)
        throw(
            LocationConflictError(
                "length of locs must be equal to the size of block, and smaller than size of itself.",
            ),
        )
    end
    return Subroutine{N,D,BT,C}(block, locs)
end

"""
    subroutine(n, block, locs)

Create a [`Subroutine`](@ref) block with total number of current active qubits `n`,
which concentrates given wire location together to `length(locs)` active qubits,
and relax the concentration afterwards.

# Example

Subroutine is equivalent to [`put`](@ref) a block on given position mathematically, but more efficient
and convenient for large blocks.

```jldoctest; setup=:(using YaoBlocks; using YaoArrayRegister)
julia> r = rand_state(3)
ArrayReg{2, ComplexF64, Array...}
    active qudits: 3/3
    nlevel: 2

julia> apply!(copy(r), subroutine(X, 1)) ≈ apply!(copy(r), put(1=>X))
true
```

It works for in-contigious locs as well

```jldoctest; setup=:(using YaoBlocks; using YaoArrayRegister)
julia> r = rand_state(4)
ArrayReg{2, ComplexF64, Array...}
    active qudits: 4/4
    nlevel: 2

julia> cc = subroutine(4, kron(X, Y), (1, 3))
nqudits: 4
Subroutine: (1, 3)
└─ kron
   ├─ 1=>X
   └─ 2=>Y

julia> pp = chain(4, put(1=>X), put(3=>Y))
nqudits: 4
chain
├─ put on (1)
│  └─ X
└─ put on (3)
   └─ Y

julia> apply!(copy(r), cc) ≈ apply!(copy(r), pp)
true
```
"""
function subroutine(n::Int, block::AbstractBlock, locs)
    return Subroutine{n}(block, Tuple(locs))
end

# support lazy qubits
subroutine(n::Int, block::Function, locs) =
    subroutine(n, parse_block(length(locs), block), locs)

"""
    subroutine(block, locs) -> f(n)

Lazy curried version of [`subroutine`](@ref).
"""
subroutine(block::AbstractBlock, locs) = @λ(n -> subroutine(n, block, locs))
subroutine(block::Function, locs) = @λ(n -> subroutine(n, block, locs))

occupied_locs(c::Subroutine) = map(i -> c.locs[i], c.content |> occupied_locs)
chsubblocks(pb::Subroutine{N}, blk::AbstractBlock) where {N} = Subroutine{N}(blk, pb.locs)
PreserveTrait(::Subroutine) = PreserveAll()

function _apply!(r::AbstractRegister, c::Subroutine)
    focus!(r, c.locs)
    _apply!(r, c.content)
    relax!(r, c.locs, to_nactive = nqudits(c))
    return r
end

function mat(::Type{T}, c::Subroutine{N,D,<:AbstractBlock}) where {N,D,T}
    mat(T, PutBlock{N}(c.content, c.locs))
end

Base.adjoint(blk::Subroutine{N}) where {N} = Subroutine{N}(adjoint(blk.content), blk.locs)

function Base.:(==)(a::Subroutine{N,D,BT}, b::Subroutine{N,D,BT}) where {N,D,BT}
    return a.content == b.content && a.locs == b.locs
end

YaoBase.nqudits(::Subroutine{N}) where {N} = N
YaoBase.nactive(c::Subroutine) = length(c.locs)

function YaoBase.iscommute(x::Subroutine{N,D}, y::Subroutine{N,D}) where {N,D}
    isempty(setdiff(occupied_locs(x), occupied_locs(y))) && return true
    if x.locs == y.locs
        return iscommute(x.content, y.content)
    else
        return iscommute_fallback(x, y)
    end
end
