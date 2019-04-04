export Sum, Prod

struct Sum{N, T, List <: Tuple} <: CompositeBlock{N, T}
    list::List

    Sum{N, T}(list::Tuple) where {N, T} = new{N, T, typeof(list)}(list)
    Sum(list::AbstractBlock{N, T}...) where {N, T} = new{N, T, typeof(list)}(list)
end

struct Prod{N, T, List <: Tuple} <: CompositeBlock{N, T}
    list::List

    Prod{N, T}(list::Tuple) where {N, T} = new{N, T, typeof(list)}(list)
    Prod(list::AbstractBlock{N, T}...) where {N, T} = new{N, T, typeof(list)}(list)
end

# merge prod & sum
Sum(a::Sum{N, T}, blks::Union{Sum{N, T}, AbstractBlock{N, T}}...) where {N, T} =
    Sum{N, T}((a.list..., ), blks...)
Sum(a::AbstractBlock{N, T}, blks::Union{Sum{N, T}, AbstractBlock{N, T}}...) where {N, T} =
    Sum{N, T}((a, ), blks...)
Sum{N, T}(a::Tuple, b::Sum, blks::Union{Sum{N, T}, AbstractBlock{N, T}}...) where {N, T} =
    Sum{N, T}((a..., b.list...), blks...)
Sum{N, T}(a::Tuple, b::AbstractBlock{N, T}, blks::Union{Sum{N, T}, AbstractBlock{N, T}}...) where {N, T} =
    Sum{N, T}((a..., b), blks...)

Prod(a::Prod{N, T}, blks::Union{Prod{N, T}, AbstractBlock{N, T}}...) where {N, T} =
    Prod{N, T}((a.list..., ), blks...)
Prod(a::AbstractBlock{N, T}, blks::Union{Prod{N, T}, AbstractBlock{N, T}}...) where {N, T} =
    Prod{N, T}((a, ), blks...)
Prod{N, T}(a::Tuple, b::Prod, blks::Union{Prod{N, T}, AbstractBlock{N, T}}...) where {N, T} =
    Prod{N, T}((a..., b.list...), blks...)
Prod{N, T}(a::Tuple, b::AbstractBlock{N, T}, blks::Union{Prod{N, T}, AbstractBlock{N, T}}...) where {N, T} =
    Prod{N, T}((a..., b), blks...)

mat(x::Sum) = mapreduce(mat, +, x.list)
mat(x::Prod) = mapreduce(mat, *, x.list)

chsubblocks(x::Sum{N, T}, it) where {N, T} = Sum{N, T}(Tuple(it))
chsubblocks(x::Prod{N, T}, it) where {N, T} = Prod{N, T}(Tuple(it))

function apply!(r::AbstractRegister{B, T}, x::Sum{N, T}) where {B, N, T}
    out = copy(r)
    apply!(out, first(x))
    for k in 2:length(x)
        out += apply!(copy(r), x[k])
    end
    copyto!(r, out)
    return r
end

function apply!(r::AbstractRegister{B, T}, x::Prod{N, T}) where {B, N, T}
    for each in Iterators.reverse(x.list)
        apply!(r, each)
    end
    return r
end

export ReduceOperator

const ReduceOperator{N, T, List} = Union{Sum{N, T, List}, Prod{N, T, List}}

apply!(r::AbstractRegister, x::ReduceOperator{N, T, Tuple{}}) where {N, T} = r
apply!(r::AbstractRegister, x::ReduceOperator{N, T, Tuple{<:AbstractBlock}}) where {N, T} =
    apply!(r, first(x))

subblocks(x::ReduceOperator) = x.list
cache_key(x::ReduceOperator) = map(cache_key, x.list)

Base.length(x::ReduceOperator) = length(x.list)
Base.iterate(x::ReduceOperator) = iterate(x.list)
Base.iterate(x::ReduceOperator, st) = iterate(x.list, st)
Base.getindex(x::ReduceOperator, k) = getindex(x.list, k)

function Base.:(==)(lhs::Prod{N, T}, rhs::Prod{N, T}) where {N, T}
    for (a, b) in zip(lhs, rhs)
        a == b || return false
    end
    return true
end

function Base.:(==)(lhs::Sum{N, T}, rhs::Sum{N, T}) where {N, T}
    for (a, b) in zip(lhs, rhs)
        a == b || return false
    end
    return true
end
