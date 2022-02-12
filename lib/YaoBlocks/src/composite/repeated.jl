using YaoBase
export RepeatedBlock, repeat

"""
    RepeatedBlock{N,D,C,GT<:AbstractBlock} <: AbstractContainer{GT,N,D}

Repeat the same block on given locations.
"""
struct RepeatedBlock{N,D,C,GT<:AbstractBlock} <: AbstractContainer{GT,N,D}
    content::GT
    locs::NTuple{C,Int}
end

function RepeatedBlock{N}(block::AbstractBlock{M,D}, locs::NTuple{C,Int}) where {N,M,D,C}
    @assert_locs_safe N Tuple(i:i+M-1 for i in locs)
    M > 1 && throw(
        ArgumentError("RepeatedBlock does not support multi-qubit content for the moment."),
    )
    return RepeatedBlock{N,D,C,typeof(block)}(block, locs)
end

function RepeatedBlock{N}(block::AbstractBlock{M,D}, locs::UnitRange{Int}) where {N,M,D}
    (0 < locs.start) && (locs.stop <= N) ||
        throw(LocationConflictError("locations conflict."))
    M > 1 && throw(
        ArgumentError("RepeatedBlock does not support multi-qubit content for the moment."),
    )
    return RepeatedBlock{N,D,length(locs),typeof(block)}(block, Tuple(locs))
end


function RepeatedBlock{N}(block::GT) where {N,M,D,GT<:AbstractBlock{M,D}}
    return RepeatedBlock{N,D,N,GT}(block, Tuple(1:M:N-M+1))
end

"""
    repeat(n, x::AbstractBlock[, locs]) -> RepeatedBlock{n}

Create a [`RepeatedBlock`](@ref) with total number of qubits `n` and the block
to repeat on given location or on all the locations.

# Example

This will create a repeat block which puts 4 X gates on each location.

```jldoctest; setup=:(using YaoBlocks)
julia> repeat(4, X)
nqudits: 4
repeat on (1, 2, 3, 4)
└─ X
```

You can also specify the location

```jldoctest; setup=:(using YaoBlocks)
julia> repeat(4, X, (1, 2))
nqudits: 4
repeat on (1, 2)
└─ X
```

But repeat won't copy the gate, thus, if it is a gate with parameter, e.g a `phase(0.1)`, the parameter
will change simultaneously.

```jldoctest; setup=:(using YaoBlocks)
julia> g = repeat(4, phase(0.1))
nqudits: 4
repeat on (1, 2, 3, 4)
└─ phase(0.1)

julia> g.content
phase(0.1)

julia> g.content.theta = 0.2
0.2

julia> g
nqudits: 4
repeat on (1, 2, 3, 4)
└─ phase(0.2)
```
"""
Base.repeat(n::Int, x::AbstractBlock, locs::Int...) = repeat(n, x, locs)
Base.repeat(n::Int, x::AbstractBlock, locs::NTuple{C,Int}) where {C} =
    RepeatedBlock{n}(x, locs)
Base.repeat(n::Int, x::AbstractBlock, locs) = repeat(n, x, locs...)
Base.repeat(n::Int, x::AbstractBlock, locs::UnitRange) = RepeatedBlock{n}(x, locs)
Base.repeat(n::Int, x::AbstractBlock) = RepeatedBlock{n}(x)
Base.repeat(x::AbstractBlock) = @λ(n -> repeat(n, x))

"""
    repeat(x::AbstractBlock, locs)

Lazy curried version of [`repeat`](@ref).
"""
Base.repeat(x::AbstractBlock, locs) = @λ(n -> repeat(n, x, locs...))

occupied_locs(rb::RepeatedBlock) =
    (vcat([(i:i+nqudits(rb.content)-1) for i in rb.locs]...)...,)
chsubblocks(x::RepeatedBlock{N}, blk::AbstractBlock) where {N} =
    RepeatedBlock{N}(blk, x.locs)
PropertyTrait(x::RepeatedBlock) = PreserveAll()

mat(::Type{T}, rb::RepeatedBlock{N,D}) where {T,N,D} =
    hilbertkron(N, fill(mat(T, rb.content), length(rb.locs)), [rb.locs...]; nlevel=D)
mat(::Type{T}, rb::RepeatedBlock{N,D,0,GT}) where {T,N,D,GT} = IMatrix{D^N,T}()

function _apply!(r::AbstractRegister, rp::RepeatedBlock)
    m = mat_matchreg(r, rp.content)
    for addr in rp.locs
        instruct!(r, m, Tuple(addr:addr+nqudits(rp.content)-1))
    end
    return r
end

# specialization
for G in [:X, :Y, :Z, :S, :T, :Sdag, :Tdag]
    GT = Expr(:(.), :ConstGate, QuoteNode(Symbol(G, :Gate)))
    @eval function _apply!(r::AbstractRegister, rp::RepeatedBlock{N,C,$GT}) where {N,C}
        instruct!(r, Val($(QuoteNode(G))), rp.locs)
        return r
    end
end

_apply!(reg::AbstractRegister, rp::RepeatedBlock{N,0}) where {N} = reg

cache_key(rb::RepeatedBlock) = (rb.locs, cache_key(rb.content))

Base.adjoint(blk::RepeatedBlock{N}) where {N} =
    RepeatedBlock{N}(adjoint(blk.content), blk.locs)
Base.copy(x::RepeatedBlock{N}) where {N} = RepeatedBlock{N}(x.content, x.locs)
Base.:(==)(A::RepeatedBlock, B::RepeatedBlock) = A.locs == B.locs && A.content == B.content

function YaoBase.iscommute(x::RepeatedBlock{N}, y::RepeatedBlock{N}) where {N}
    if x.locs == y.locs
        return iscommute(x.content, y.content)
    else
        iscommute_fallback(x, y)
    end
end
