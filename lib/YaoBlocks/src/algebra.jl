# A Simple Computational Algebra System

_mul(::Val{X}, ::Val{Y}) where {X, Y} = Val(X*Y)
_mul(x::Number, y::Number) = x * y
_neg(::Val{X}) where X = Val(-X)
_neg(x::Number) = x

# negate
Base.:(-)(x::AbstractBlock) = Scale(Val(-1), x)
Base.:(-)(x::Scale{Val{-1}}) = content(x)
Base.:(-)(x::Scale) = Scale(_neg(x.alpha), content(x))

# scaler multiply block
Base.:(*)(α::T, x::AbstractBlock) where {T<:Union{Val, Number}} = Scale(α, x)
Base.:(*)(α::T, x::Scale) where {T<:Union{Val, Number}} = Scale(_mul(α, x.alpha), content(x))
Base.:(*)(x::AbstractBlock, α::Union{Val, Number}) = α * x

# block multiply block
Base.:(*)(x::Scale, y::Scale) = (_mul(x.alpha, y.alpha)) * (content(x) * content(y))
Base.:(*)(x::Scale, y::AbstractBlock) = x.alpha * chain(y, content(x))
Base.:(*)(y::AbstractBlock, x::Scale) = x.alpha * chain(content(x), y)
Base.:(*)(xs::AbstractBlock...) = chain(Iterators.reverse(xs)...)

# add
Base.:(+)(xs::AbstractBlock...) = Add(xs...)

# div
Base.:(/)(A::AbstractBlock, x::Number) = (1 / x) * A

# reduce
Base.prod(blocks::AbstractVector{<:AbstractBlock{D}}) where D =
    chain(Iterators.reverse(blocks)...)
Base.sum(blocks::AbstractVector{<:AbstractBlock{D}}) where D = +(blocks...)

#sub
Base.:(-)(lhs::AbstractBlock, rhs::AbstractBlock) = Add(lhs, -rhs)

# pow
Base.:(^)(x::AbstractBlock, n::Int) = chain((copy(x) for k = 1:n)...)
