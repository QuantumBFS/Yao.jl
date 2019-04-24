using LinearAlgebra

export Scale

struct Scale{S <: Union{Number, Val}, N, T, BT <: AbstractBlock{N, T}} <: TagBlock{BT, N, T}
    alpha::S
    content::BT
end

content(x::Scale) = x.content
Base.copy(x::Scale) = Scale(x.alpha, copy(x.content))
Base.adjoint(x::Scale) = Scale(adjoint(x.alpha), adjoint(content(x)))

Base.:(==)(x::Scale, y::Scale) = (x.alpha == y.alpha) && (content(x) == content(y))

chsubblocks(x::Scale, blk::AbstractBlock) = Scale(x.alpha, blk)
cache_key(x::Scale) = (x.alpha, cache_key(content(x)))

mat(x::Scale) = x.alpha * mat(content(x))
mat(x::Scale{Val{S}}) where S = S * mat(content(x))

function apply!(r::ArrayReg{B, T}, x::Scale{S, N, T}) where {S, B, N, T}
    apply!(r, content(x))
    r.state *= x.alpha
    return r
end
