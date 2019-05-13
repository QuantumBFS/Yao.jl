using YaoBase
export Concentrator, concentrate

"""
    Concentrator{N, T, BT <: AbstractBlock} <: AbstractContainer{BT, N, T}

concentrates serveral lines together in the circuit, and expose
it to other blocks.
"""
struct Concentrator{N, BT <: AbstractBlock, C} <: AbstractContainer{BT, N}
    content::BT
    locations::NTuple{C, Int}
end

function Concentrator{N}(block::BT, locations::NTuple{C, Int}) where {N, M, C, BT<:AbstractBlock{M}}
    if !(length(locations) == M && N>=M)
        throw(LocationConflictError("length of locations must be equal to the size of block, and smaller than size of itself."))
    end
    return Concentrator{N, BT, C}(block, locations)
end

"""
    concentrate(n, block, locs)

Create a [`Concentrator`](@ref) block with total number of current active qubits `n`,
which concentrates given wire location together to `length(locs)` active qubits,
and relax the concentration afterwards.

# Example

Concentrator is equivalent to [`put`](@ref) a block on given position mathematically, but more efficient
and convenient for large blocks.

```jldoctest
julia> r = rand_state(3)
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 3/3

julia> apply!(copy(r), concentrate(X, 1)) ≈ apply!(copy(r), put(1=>X))
true
```

It works for in-contigious locations as well

```jldoctest
julia> r = rand_state(4)
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 4/4

julia> cc = concentrate(4, kron(X, Y), (1, 3))
nqubits: 4
Concentrator: (1, 3)
└─ kron
   ├─ 1=>X gate
   └─ 2=>Y gate

julia> pp = chain(4, put(1=>X), put(3=>Y))
nqubits: 4
chain
├─ put on (1)
│  └─ X gate
└─ put on (3)
   └─ Y gate

julia> apply!(copy(r), cc) ≈ apply!(copy(r), pp)
true
```
"""
function concentrate(n::Int, block::AbstractBlock, locs)
    return Concentrator{n}(block, Tuple(locs))
end

# support lazy qubits
concentrate(n::Int, block::Function, locs) = concentrate(n, parse_block(length(locs), block), locs)

"""
    concentrate(block, locs) -> f(n)

Lazy curried version of [`concentrate`](@ref).
"""
concentrate(block::AbstractBlock, locs) = @λ(n->concentrate(n, block, locs))
concentrate(block::Function, locs) = @λ(n->concentrate(n, block, locs))

occupied_locs(c::Concentrator) = c.locations
chsubblocks(pb::Concentrator{N}, blk::AbstractBlock) where N =
    Concentrator{N}(blk, occupied_locs(pb))
PreserveStyle(::Concentrator) = PreserveAll()

function apply!(r::AbstractRegister, c::Concentrator)
    _check_size(r, c)
    focus!(r, occupied_locs(c))
    apply!(r, c.content)
    relax!(r, occupied_locs(c), to_nactive=nqubits(c))
    return r
end

function mat(::Type{T}, c::Concentrator{N, <:AbstractBlock}) where {N, T}
    mat(T, PutBlock{N}(c.content, c.locations))
end

Base.adjoint(blk::Concentrator{N}) where N =
    Concentrator{N}(adjoint(blk.content), occupied_locs(blk))

function Base.:(==)(a::Concentrator{N, BT}, b::Concentrator{N, BT}) where {N, BT}
    return a.content == b.content && a.locations == b.locations
end

YaoBase.nqubits(::Concentrator{N}) where N = N
YaoBase.nactive(c::Concentrator) = length(c.locations)

function YaoBase.iscommute(x::Concentrator{N}, y::Concentrator{N}) where N
    if occupied_locs(x) == occupied_locs(y)
        return iscommute(x.content, y.content)
    else
        return iscommute_fallback(x, y)
    end
end
