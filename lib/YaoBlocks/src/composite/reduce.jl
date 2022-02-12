using SimpleTraits.BaseTraits, SimpleTraits

export Add

"""
    Add{N,D} <: CompositeBlock{N,D}
    Add(blocks::AbstractBlock...) -> Add
"""
struct Add{N,D} <: CompositeBlock{N,D}
    list::Vector{AbstractBlock{N,D}}
    Add{N,D}(blocks::Vector{AbstractBlock{N,D}}) where {N,D} = new{N,D}(blocks)
    Add(blocks::Vector{<:AbstractBlock{N,D}}) where {N,D} = new{N,D}(collect(AbstractBlock{N,D}, blocks))
    Add{N}(; nlevel=2) where {N} = new{N,nlevel}(AbstractBlock{N,nlevel}[])
end

Add{N,D}(blocks) where {N,D} = Add{N,D}(collect(AbstractBlock{N,D}, blocks))
Add(blocks::AbstractBlock{N,D}...) where {N,D} = Add{N,D}(blocks)

function mat(::Type{T}, x::Add{N,D}) where {N,D,T}
    length(x.list) == 0 && return Diagonal(zeros(T, D^N))
    mapreduce(x -> mat(T, x), +, x.list)
end

chsubblocks(x::Add{N,D}, it) where {N,D} = Add{N,D}(it)

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
Base.copy(x::Add{N,D}) where {N,D} = Add{N,D}(copy(x.list))
Base.similar(c::Add{N,D}) where {N,D} = Add{N,D}(empty!(similar(c.list)))

function Base.:(==)(lhs::Add{N,D}, rhs::Add{N,D}) where {N,D}
    (length(lhs.list) == length(rhs.list)) && all(lhs.list .== rhs.list)
end

for FUNC in [:length, :iterate, :getindex, :eltype, :eachindex, :popfirst!, :lastindex]
    @eval Base.$FUNC(x::Add, args...) = $FUNC(subblocks(x), args...)
end

Base.getindex(c::Add{N,D}, index::Union{UnitRange,Vector}) where {N,D} =
    Add{N,D}(getindex(c.list, index))
Base.setindex!(c::Add{N,D}, val::AbstractBlock{N,D}, index::Integer) where {N,D} =
    (setindex!(c.list, val, index); c)
Base.insert!(c::Add{N,D}, index::Integer, val::AbstractBlock{N,D}) where {N,D} =
    (insert!(c.list, index, val); c)
Base.adjoint(blk::Add{N,D}) where {N,D} = Add{N,D}(map(adjoint, subblocks(blk)))

## Iterate contained blocks
occupied_locs(c::Add) =
    (unique(Iterators.flatten(occupied_locs(b) for b in subblocks(c)))...,)

# Additional Methods for Add
Base.push!(c::Add{N,D}, val::AbstractBlock{N,D}) where {N,D} = (push!(c.list, val); c)

function Base.push!(c::Add{N,D}, val::Function) where {N,D}
    push!(c, val(N))
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

YaoBase.ishermitian(ad::Add) = all(ishermitian, ad.list) || ishermitian(mat(ad))
