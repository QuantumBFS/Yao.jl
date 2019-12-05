using SimpleTraits.BaseTraits, SimpleTraits

export Add

"""
    Add{N} <: CompositeBlock{N}
    Add{N}(iterable) -> Add
    Add(blocks::AbstractBlock{N}...) -> Add
"""
struct Add{N} <: CompositeBlock{N}
    list::Vector{AbstractBlock{N}}

    Add{N}(list::Vector{AbstractBlock{N}}) where {N} = new{N}(list)
    Add{N}() where {N} = new{N}(AbstractBlock{N}[])
end

#Add{N}() where N = Add{N}(AbstractBlock{N}[])
Add{N}(blocks) where {N} = Add{N}(collect(AbstractBlock{N}, blocks))
Add(blocks::AbstractBlock{N}...) where {N} = Add{N}(blocks)

mat(::Type{T}, x::Add) where {T} = mapreduce(x -> mat(T, x), +, x.list)

chsubblocks(x::Add{N}, it) where {N} = Add{N}(it)

function apply!(r::AbstractRegister, x::Add)
    isempty(x.list) && return r
    length(x.list) == 1 && return apply!(r, x.list[])

    res = mapreduce(blk -> apply!(copy(r), blk), regadd!, x.list[1:end-1])
    apply!(r, x.list[end])
    regadd!(r, res)
    r
end

export Add

subblocks(x::Add) = x.list
cache_key(x::Add) = map(cache_key, x.list)
Base.copy(x::Add{N}) where {N} = Add{N}(copy(x.list))
Base.similar(c::Add{N}) where {N} = Add{N}(empty!(similar(c.list)))

function Base.:(==)(lhs::Add{N}, rhs::Add{N}) where {N}
    (length(lhs.list) == length(rhs.list)) && all(lhs.list .== rhs.list)
end

for FUNC in [:length, :iterate, :getindex, :eltype, :eachindex, :popfirst!, :lastindex]
    @eval Base.$FUNC(x::Add, args...) = $FUNC(subblocks(x), args...)
end

Base.getindex(c::Add{N}, index::Union{UnitRange,Vector}) where {N} = Add{N}(getindex(c.list, index))
Base.setindex!(c::Add{N}, val::AbstractBlock{N}, index::Integer) where {N} =
    (setindex!(c.list, val, index); c)
Base.insert!(c::Add{N}, index::Integer, val::AbstractBlock{N}) where {N} =
    (insert!(c.list, index, val); c)
Base.adjoint(blk::Add{N}) where {N} = Add{N}(map(adjoint, subblocks(blk)))

## Iterate contained blocks
occupied_locs(c::Add) = (unique(Iterators.flatten(occupied_locs(b) for b in subblocks(c)))...,)

# Additional Methods for Add
Base.push!(c::Add{N}, val::AbstractBlock{N}) where {N} = (push!(c.list, val); c)

function Base.push!(c::Add{N}, val::Function) where {N}
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
