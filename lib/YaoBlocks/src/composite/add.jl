export Add

"""
    Add{D} <: CompositeBlock{D}
    Add(blocks::AbstractBlock...) -> Add

Type for block addition.

```jldoctest; setup=:(using Yao)
julia> X + X
nqubits: 1
+
├─ X
└─ X
```
"""
struct Add{D} <: CompositeBlock{D}
    n::Int
    list::Vector{AbstractBlock{D}}
    Add(n::Int, blocks::Vector{AbstractBlock{D}}) where {D} = new{D}(_check_block_sizes(blocks, n), blocks)
    Add(blocks::Vector{AbstractBlock{D}}) where {D} = new{D}(_check_block_sizes(blocks), blocks)
    Add(n::Int; nlevel=2) = new{nlevel}(n, AbstractBlock{nlevel}[])
end

Add(blocks::NTuple{M,AbstractBlock{D}}) where {M,D} = Add(collect(AbstractBlock{D}, blocks))
Add(n::Int, blocks::AbstractVector{<:AbstractBlock{D}}) where {D} = Add(n, collect(AbstractBlock{D}, blocks))
Add(blocks::AbstractVector{<:AbstractBlock{D}}) where {D} = Add(collect(AbstractBlock{D}, blocks))
Add(block::AbstractBlock{D}, blocks::AbstractBlock{D}...) where {D} = Add(AbstractBlock{D}[block, blocks...])
nqudits(add::Add) = add.n

function mat(::Type{T}, x::Add{D}) where {D,T}
    length(x.list) == 0 && return Diagonal(zeros(T, D^x.n))
    mapreduce(x -> mat(T, x), +, x.list)
end

chsubblocks(x::Add, it) = Add(it)

function _apply!(r::AbstractRegister, x::Add)
    isempty(x.list) && return r
    length(x.list) == 1 && return _apply!(r, x.list[])

    res = mapreduce(blk -> _apply!(copy(r), blk), regadd!, x.list[1:end-1])
    _apply!(r, x.list[end])
    regadd!(r, res)
    r
end

export Add

subblocks(x::Add) = x.list
cache_key(x::Add) = map(cache_key, x.list)
Base.copy(x::Add) = Add(x.n, copy(x.list))
Base.similar(c::Add) = Add(c.n, empty!(similar(c.list)))

function Base.:(==)(lhs::Add{D}, rhs::Add{D}) where {D}
    nqudits(lhs) == nqudits(rhs) && (length(lhs.list) == length(rhs.list)) && all(lhs.list .== rhs.list)
end

for FUNC in [:length, :iterate, :getindex, :eltype, :eachindex, :popfirst!, :lastindex]
    @eval Base.$FUNC(x::Add, args...) = $FUNC(subblocks(x), args...)
end

Base.getindex(c::Add{D}, index::Union{UnitRange,Vector}) where {D} =
    Add(c.n, getindex(c.list, index))
Base.setindex!(c::Add{D}, val::AbstractBlock{D}, index::Integer) where {D} =
    (setindex!(c.list, val, index); c)
Base.insert!(c::Add{D}, index::Integer, val::AbstractBlock{D}) where {D} =
    (insert!(c.list, index, val); c)
Base.adjoint(blk::Add{D}) where {D} = Add(blk.n, map(adjoint, subblocks(blk)))

## Iterate contained blocks
occupied_locs(c::Add) =
    (unique(Iterators.flatten(occupied_locs(b) for b in subblocks(c)))...,)

# Additional Methods for Add
Base.push!(c::Add{D}, val::AbstractBlock{D}) where {D} = (_check_block_sizes(c, val); push!(c.list, val); c)

function Base.push!(c::Add{D}, val::Function) where {D}
    push!(c, val(c.n))
end

function Base.append!(c::Add, list)
    for blk in list
        push!(c, blk)
    end
    c
end

function Base.prepend!(c::Add, list)
    for blk in list[end:-1:1]
        insert!(c, 1, blk)
    end
    c
end

LinearAlgebra.ishermitian(ad::Add) = all(ishermitian, ad.list) || ishermitian(mat(ad))

# this is not type stable, possible to fix?
function unsafe_getindex(ad::Add{D}, i::Integer, j::Integer) where D
    length(ad.list) > 0 ? sum(b->unsafe_getindex(b,i,j), ad.list) : 0.0im
end
function Base.getindex(b::Add{D}, i::DitStr{D,N}, j::DitStr{D,N}) where {D,N}
    @assert nqudits(b) == N
    return unsafe_getindex(b, buffer(i), buffer(j))
end