using LinearAlgebra

export Scale, factor

"""
    Scale{S <: Union{Number, Val}, N, BT <: AbstractBlock{N}} <: TagBlock{BT, N}

`Scale` a block with scalar. it can be either a `Number` or a compile time `Val`.

# Example

```jldoctest
julia> 2 * X
[scale: 2] X gate

julia> im * Z
[+im] Z gate

julia> -im * Z
[-im] Z gate

julia> -Z
[-] Z gate
```
"""
struct Scale{S <: Union{Number, Val}, N, BT <: AbstractBlock{N}} <: TagBlock{BT, N}
    alpha::S
    content::BT
end

content(x::Scale) = x.content
factor(x::Scale{<:Number}) = x.alpha
factor(x::Scale{Val{X}}) where X = X

Base.copy(x::Scale) = Scale(x.alpha, copy(x.content))
Base.adjoint(x::Scale{<:Number}) = Scale(adjoint(x.alpha), adjoint(content(x)))
Base.adjoint(x::Scale{Val{X}}) where X = Scale(Val(adjoint(X)), adjoint(content(x)))

Base.:(==)(x::Scale, y::Scale) = (factor(x) == factor(y)) && (content(x) == content(y))

chsubblocks(x::Scale, blk::AbstractBlock) = Scale(x.alpha, blk)
cache_key(x::Scale) = (factor(x), cache_key(content(x)))

mat(::Type{T}, x::Scale) where T = T(x.alpha) * mat(T, content(x))
mat(::Type{T}, x::Scale{Val{S}}) where {T, S} = T(S) * mat(T, content(x))

function apply!(r::ArrayReg{B}, x::Scale{S, N}) where {S, B, N}
    apply!(r, content(x))
    r.state .*= factor(x)
    return r
end
