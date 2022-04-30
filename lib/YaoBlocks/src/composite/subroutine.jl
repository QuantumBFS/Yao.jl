export Subroutine, subroutine

"""
    Subroutine{D, BT <: AbstractBlock, C} <: AbstractContainer{BT, D}

Subroutine node on given locations. This allows you to shoehorn a smaller
circuit to a larger one.
"""
struct Subroutine{D,BT<:AbstractBlock,C} <: AbstractContainer{BT,D}
    n::Int
    content::BT
    locs::NTuple{C,Int}
end

function Subroutine(n::Int, block::BT, locs::NTuple{C,Int}) where {N,D,C,BT<:AbstractBlock{D}}
    @assert_locs_safe n locs
    if !(length(locs) == nqudits(block) && n>= nqudits(block))
        throw(
            LocationConflictError(
                "length of locs must be equal to the size of block, and smaller than size of itself.",
            ),
        )
    end
    return Subroutine{D,BT,C}(n, block, locs)
end
YaoAPI.nqudits(b::Subroutine) = b.n

"""
    subroutine(n, block, locs)

Create a `n`-qudit [`Subroutine`](@ref) block, where the `subblock` is a subprogram of size `m`, and `locs` is a tuple or range of length `m`.
It runs a quantum subprogram with smaller size on a subset of locations.
While its mathematical definition is the same as the [`put`](@ref) block, while it is more suited for running a larger chunk of circuit.

### Examples

Subroutine is equivalent to [`put`](@ref) a block on given position mathematically, but more efficient
and convenient for large blocks.

```jldoctest; setup=:(using Yao)
julia> r = rand_state(3)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 3/3
    nlevel: 2

julia> apply!(copy(r), subroutine(X, 1)) ≈ apply!(copy(r), put(1=>X))
true
```

It works for in-contigious locs as well

```jldoctest; setup=:(using Yao)
julia> r = rand_state(4)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 4/4
    nlevel: 2

julia> cc = subroutine(4, kron(X, Y), (1, 3))
nqubits: 4
Subroutine: (1, 3)
└─ kron
   ├─ 1=>X
   └─ 2=>Y

julia> pp = chain(4, put(1=>X), put(3=>Y))
nqubits: 4
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
    return Subroutine(n, block, Tuple(locs))
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
chsubblocks(pb::Subroutine{D}, blk::AbstractBlock{D}) where {D} = Subroutine(pb.n, blk, pb.locs)
PropertyTrait(::Subroutine) = PreserveAll()

function _apply!(r::AbstractRegister, c::Subroutine)
    focus!(r, c.locs)
    _apply!(r, c.content)
    relax!(r, c.locs, to_nactive = nqudits(c))
    return r
end

function mat(::Type{T}, c::Subroutine{D,<:AbstractBlock}) where {D,T}
    mat(T, PutBlock(c.n, c.content, c.locs))
end

Base.adjoint(blk::Subroutine) = Subroutine(blk.n, adjoint(blk.content), blk.locs)

function Base.:(==)(a::Subroutine{D,BT}, b::Subroutine{D,BT}) where {D,BT}
    return a.n == b.n && a.content == b.content && a.locs == b.locs
end

YaoAPI.nactive(c::Subroutine) = length(c.locs)

function YaoAPI.iscommute(x::Subroutine{D}, y::Subroutine{D}) where {D}
    _check_block_sizes(x, y)
    isempty(setdiff(occupied_locs(x), occupied_locs(y))) && return true
    if x.locs == y.locs
        return iscommute(x.content, y.content)
    else
        return iscommute_fallback(x, y)
    end
end
