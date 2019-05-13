using SimpleTraits.BaseTraits, SimpleTraits

export Sum

struct Sum{N} <: CompositeBlock{N}
    list::Vector{AbstractBlock{N}}

    Sum{N}(list::Vector{AbstractBlock{N}}) where N = new{N}(list)
    Sum{N}(it::T) where {N, T} = Sum{N}(SimpleTraits.trait(IsIterator{T}), it)
    Sum{N}(::Type{<:IsIterator}, it) where N = new{N}(collect(AbstractBlock{N}, it))
end

Sum{N}(::Not, it) where N = error("expect an iterator/collection")

Sum{N}() where N = Sum(AbstractBlock{N}[])
Sum(blocks::Vector{<:AbstractBlock{N}}) where N = Sum{N}(blocks)
Sum(blocks::AbstractBlock{N}...) where N = Sum(collect(AbstractBlock{N}, blocks))

mat(::Type{T}, x::Sum) where T = mapreduce(x->mat(T, x), +, x.list)

chsubblocks(x::Sum{N}, it) where N = Sum{N}(it)

function apply!(r::AbstractRegister, x::Sum)
    isempty(x.list) && return r

    out = copy(r)
    apply!(out, first(x))
    for k in 2:length(x)
        out += apply!(copy(r), x[k])
    end
    copyto!(r, out)
    return r
end

export Sum

subblocks(x::Sum) = x.list
cache_key(x::Sum) = map(cache_key, x.list)

Base.length(x::Sum) = length(x.list)
Base.iterate(x::Sum) = iterate(x.list)
Base.iterate(x::Sum, st) = iterate(x.list, st)
Base.getindex(x::Sum, k) = getindex(x.list, k)

function Base.:(==)(lhs::Sum{N}, rhs::Sum{N}) where N
    for (a, b) in zip(lhs, rhs)
        a == b || return false
    end
    return true
end
