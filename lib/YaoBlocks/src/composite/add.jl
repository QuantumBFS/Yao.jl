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

function YaoAPI.unsafe_apply!(r::AbstractRegister, x::Add)
    isempty(x.list) && return r
    length(x.list) == 1 && return YaoAPI.unsafe_apply!(r, x.list[])

    res = mapreduce(blk -> YaoAPI.unsafe_apply!(copy(r), blk), regadd!, x.list[1:end-1])
    YaoAPI.unsafe_apply!(r, x.list[end])
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
function unsafe_getindex(::Type{T}, ad::Add{D}, i::Integer, j::Integer) where {T, D}
    length(ad.list) > 0 ? sum(b->unsafe_getindex(T,b,i,j), ad.list) : zero(T)
end
function unsafe_getcol(::Type{T}, ad::Add{D}, j::DitStr{D,N,TI}) where {T,D,N,TI}
    length(ad.list) == 0 && return DitStr{D,N,TI}[], T[]
    locs = Vector{DitStr{D,N,TI}}[]
    amps = Vector{T}[]
    for block in ad.list
        loc, amp = unsafe_getcol(T, block, j)
        push!(locs, loc)
        push!(amps, amp)
    end
    return vcat(locs...), vcat(amps...)
end
function Base.getindex(b::Add{D}, i::DitStr{D,N}, j::DitStr{D,N}) where {D,N}
    invoke(Base.getindex, Tuple{AbstractBlock{D}, DitStr{D,N}, DitStr{D,N}} where {D,N}, b, i, j)
end
function Base.getindex(b::Add{D}, ::Colon, j::DitStr{D,N}) where {D,N}
    T = promote_type(ComplexF64, parameters_eltype(b))
    return _getindex(T, b, :, j)
end
function Base.getindex(b::Add{D}, i::DitStr{D,N}, ::Colon) where {D,N}
    T = promote_type(ComplexF64, parameters_eltype(b))
    return _getindex(T, b, i, :)
end
# the performance of this block important! so specialize it will make it slightly faster.
function Base.getindex(ad::Add{D}, ::Colon, j::EntryTable{DitStr{D,N,TI},T}) where {D,N,TI,T}
    cfgs = Vector{DitStr{D,N,TI}}[]
    amps = Vector{T}[]
    for b in ad.list
        _single_block!(cfgs, amps, b, j)
    end
    return merge(EntryTable(vcat(cfgs...), vcat(amps...)))
end
function _single_block!(cfgs, amps, b, j::EntryTable)
    for (c, a) in zip(j.configs, j.amplitudes)
        et = b[:,c]
        rmul!(et.amplitudes, a)
        push!(cfgs, et.configs)
        push!(amps, et.amplitudes)
    end
end
function Base.getindex(ad::Add{D}, i::EntryTable{DitStr{D,N,TI},T}, ::Colon) where {D,N,TI,T}
    return _getindex(ad, i, :)
end