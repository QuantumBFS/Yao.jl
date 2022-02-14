# A Simple Computational Algebra System

# scale
Base.:(-)(x::AbstractBlock) = Scale(Val(-1), x)
Base.:(-)(x::Scale{Val{-1}}) = content(x)
Base.:(-)(x::Scale{Val{S}}) where {S} = Scale(Val(-S), content(x))
Base.:(-)(x::Scale) = Scale(-x.alpha, content(x))

Base.:(*)(x::AbstractBlock, α::Number) = α * x

# NOTE: ±,±im should be identical
Base.:(*)(α::Val{S}, x::AbstractBlock) where {S} = Scale(α, x)

function Base.:(*)(α::T, x::AbstractBlock) where {T<:Number}
    return α == one(T) ? x :
           α == -one(T) ? Scale(Val(-1), x) :
           α == im ? Scale(Val(im), x) : α == -im ? Scale(Val(-im), x) : Scale(α, x)
end

Base.:(*)(α::T, x::Scale) where {T<:Number} =
    α == one(T) ? x : Scale(x.alpha * α, content(x))
Base.:(*)(α::T, x::Scale{Val{S}}) where {T<:Number,S} = α * S * content(x)

Base.:(*)(x::Scale, y::Scale) = (factor(x) * factor(y)) * (content(x) * content(y))
Base.:(*)(x::Scale, y::AbstractBlock) = factor(x) * chain(y, content(x))
Base.:(*)(y::AbstractBlock, x::Scale) = factor(x) * chain(content(x), y)

Base.:(+)(xs::AbstractBlock...) = Add(xs...)
Base.:(*)(xs::AbstractBlock...) = chain(Iterators.reverse(xs)...)
Base.:(/)(A::AbstractBlock, x::Number) = (1 / x) * A
# reduce
Base.prod(blocks::AbstractVector{<:AbstractBlock{D}}) where D =
    chain(Iterators.reverse(blocks)...)
Base.sum(blocks::AbstractVector{<:AbstractBlock{D}}) where D = +(blocks...)

Base.:(-)(lhs::AbstractBlock, rhs::AbstractBlock) = Add(lhs, -rhs)
Base.:(^)(x::AbstractBlock, n::Int) = chain((copy(x) for k = 1:n)...)
