# A Simple Computational Algebra System

# scale
Base.:(-)(x::AbstractBlock{N}) where {N} = Scale(Val(-1), x)
Base.:(-)(x::Scale{Val{-1}}) = content(x)
Base.:(-)(x::Scale{Val{S}}) where S = Scale(Val(-S), content(x))
Base.:(-)(x::Scale) = Scale(-x.alpha, content(x))

Base.:(*)(x::AbstractBlock, α::Number) = α * x

# NOTE: ±,±im should be identical
Base.:(*)(α::Val{S}, x::AbstractBlock) where S = Scale(α, x)

function Base.:(*)(α::T, x::AbstractBlock) where T <: Number
    return α ==  one(T) ? x                 :
    α == -one(T) ? Scale(Val(-1), x)   :
    α ==      im ? Scale(Val(im), x)        :
    α ==     -im ? Scale(Val(-im), x)       :
    Scale(α, x)
end

Base.:(*)(α::T, x::Scale) where {T <: Number} = α == one(T) ? x : Scale(x.alpha * α, content(x))
Base.:(*)(α::T, x::Scale{Val{S}}) where {T <: Number, S} = α * S * content(x)

Base.:(*)(α::Val{S}, x::Scale) where S = (S * x.alpha) * content(x)
Base.:(*)(α::Val{S1}, x::Scale{Val{S2}}) where {S1, S2} = (S1 * S2) * content(x)

Base.:(*)(x::Scale, y::Scale) = (x.alpha * y.alpha) * (content(x) * content(y))
Base.:(*)(x::Scale{Val{S1}}, y::Scale{Val{S2}}) where {S1, S2} = (S1 * S2) * (content(x) * content(y))
Base.:(*)(x::Scale, y::Scale{Val{S}}) where S = (x.alpha * S) * (content(x) * content(y))
Base.:(*)(x::Scale{Val{S}}, y::Scale) where S = (S * y.alpha) * (content(x) * content(y))
Base.:(*)(x::Scale, y::AbstractBlock) = x.alpha * chain(y, content(x))
Base.:(*)(y::AbstractBlock, x::Scale) = x.alpha * chain(content(x), y)

Base.:(+)(xs::AbstractBlock...) = Add(xs...)
Base.:(*)(xs::AbstractBlock...) = chain(Iterators.reverse(xs)...)
Base.:(/)(A::AbstractBlock, x::Number) = (1/x)*A
# reduce
Base.prod(blocks::AbstractVector{<:AbstractBlock{N}}) where N = chain(Iterators.reverse(blocks)...)
Base.sum(blocks::AbstractVector{<:AbstractBlock{N}}) where N = +(blocks...)

Base.:(-)(lhs::AbstractBlock, rhs::AbstractBlock) = Add(lhs, -rhs)
Base.:(^)(x::AbstractBlock, n::Int) = chain((copy(x) for k in 1:n)...)
