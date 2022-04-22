export RepeatedBlock, repeat

"""
    RepeatedBlock{D,C,GT<:AbstractBlock} <: AbstractContainer{GT,D}

Repeat the same block on given locations.
"""
struct RepeatedBlock{D,C,GT<:AbstractBlock} <: AbstractContainer{GT,D}
    n::Int
    content::GT
    locs::NTuple{C,Int}
end

function RepeatedBlock(n::Int, block::AbstractBlock{D}, locs::NTuple{C,Int}) where {D,C}
    @assert_locs_safe n Tuple(i:i+nqudits(block)-1 for i in locs)
    nqudits(block) > 1 && throw(
        ArgumentError("RepeatedBlock does not support multi-qubit content for the moment."),
    )
    return RepeatedBlock{D,C,typeof(block)}(n, block, locs)
end

function RepeatedBlock(n::Int, block::AbstractBlock{D}, locs::UnitRange{Int}) where {D}
    (0 < locs.start) && (locs.stop <= n) ||
        throw(LocationConflictError("locations conflict."))
    nqudits(block) > 1 && throw(
        ArgumentError("RepeatedBlock does not support multi-qubit content for the moment."),
    )
    return RepeatedBlock{D,length(locs),typeof(block)}(n, block, Tuple(locs))
end


function RepeatedBlock(n::Int, block::GT) where {M,D,GT<:AbstractBlock{D}}
    return RepeatedBlock{D,n,GT}(n::Int, block, Tuple(1:nqudits(block):n-nqudits(block)+1))
end
YaoAPI.nqudits(m::RepeatedBlock) = m.n

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
    RepeatedBlock(n, x, locs)
Base.repeat(n::Int, x::AbstractBlock, locs) = repeat(n, x, locs...)
Base.repeat(n::Int, x::AbstractBlock, locs::UnitRange) = RepeatedBlock(n, x, locs)
Base.repeat(n::Int, x::AbstractBlock) = RepeatedBlock(n, x)
Base.repeat(x::AbstractBlock) = @λ(n -> repeat(n, x))

"""
    repeat(x::AbstractBlock, locs)

Lazy curried version of [`repeat`](@ref).
"""
Base.repeat(x::AbstractBlock, locs) = @λ(n -> repeat(n, x, locs...))

occupied_locs(rb::RepeatedBlock) =
    (vcat([(i:i+nqudits(rb.content)-1) for i in rb.locs]...)...,)
chsubblocks(x::RepeatedBlock{D}, blk::AbstractBlock{D}) where {D} =
    RepeatedBlock(x.n, blk, x.locs)
PropertyTrait(x::RepeatedBlock) = PreserveAll()

mat(::Type{T}, rb::RepeatedBlock{D}) where {T,D} =
    YaoArrayRegister.hilbertkron(rb.n, fill(mat(T, rb.content), length(rb.locs)), [rb.locs...]; nlevel=D)
mat(::Type{T}, rb::RepeatedBlock{D,0,GT}) where {T,D,GT} = IMatrix{D^nqudits(rb),T}()

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

_apply!(reg::AbstractRegister, rp::RepeatedBlock{D,0}) where D = reg

cache_key(rb::RepeatedBlock) = (rb.locs, cache_key(rb.content))

Base.adjoint(blk::RepeatedBlock{D}) where {D} =
    RepeatedBlock(nqudits(blk), adjoint(blk.content), blk.locs)
Base.copy(x::RepeatedBlock) = RepeatedBlock(nqudits(x), x.content, x.locs)
Base.:(==)(A::RepeatedBlock, B::RepeatedBlock) = A.locs == B.locs && A.content == B.content

function YaoAPI.iscommute(x::RepeatedBlock{D}, y::RepeatedBlock{D}) where {D}
    if nqudits(x) != nqudits(y)
        throw(QubitMismatchError("got nqudits = `$(nqudits(x))` and `$(nqudits(y))`"))
    end
    if x.locs == y.locs
        return iscommute(x.content, y.content)
    else
        iscommute_fallback(x, y)
    end
end
