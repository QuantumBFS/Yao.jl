export Scale, factor

"""
    Scale{S <: Union{Number, Val}, D, BT <: AbstractBlock{D}} <: TagBlock{BT, D}
    Scale(factor, block)

Multiply a block with a scalar factor, which can be a number or a `Val`.
If the factor is a number, it is regarded as a parameter that can be changed dynamically.
If the factor is a `Val`, it is regarded as a constant.

### Examples

```jldoctest; setup=:(using YaoBlocks)
julia> 2 * X
[scale: 2] X

julia> im * Z
[+im] Z

julia> -im * Z
[-im] Z

julia> -Z
[-] Z
```
"""
mutable struct Scale{S<:Union{Number,Val},D,BT<:AbstractBlock{D}} <: TagBlock{BT,D}
    alpha::S
    content::BT
end

content(x::Scale) = x.content
factor(x::Scale{<:Number}) = x.alpha
factor(x::Scale{Val{X}}) where {X} = X

# parameter interface
getiparams(s::Scale{<:Number}) = (factor(s),)
setiparams(s::Scale{<:Number}, alpha::Number) = Scale(alpha, s.content)
setiparams!(s::Scale{T1}, alpha::T2) where {T1<:Number, T2<:Number} = (s.alpha = T1(alpha); s)

Base.copy(x::Scale) = Scale(x.alpha, copy(x.content))
Base.adjoint(x::Scale{<:Number}) = Scale(adjoint(x.alpha), adjoint(content(x)))
Base.adjoint(x::Scale{Val{X}}) where {X} = Scale(Val(adjoint(X)), adjoint(content(x)))

LinearAlgebra.ishermitian(s::Scale) =
    (ishermitian(s |> content) && ishermitian(s |> factor)) || ishermitian(mat(s))
YaoAPI.isunitary(s::Scale) =
    (isunitary(s |> content) && isunitary(s |> factor)) || isunitary(mat(s))
YaoAPI.isreflexive(s::Scale) =
    (isreflexive(s |> content) && isreflexive(s |> factor)) || isreflexive(mat(s))
YaoAPI.iscommute(x::Scale, y::Scale) = iscommute(x |> content, y |> content)
YaoAPI.iscommute(x::AbstractBlock, y::Scale) = iscommute(x, y |> content)
YaoAPI.iscommute(x::Scale, y::AbstractBlock) = iscommute(x |> content, y)

Base.:(==)(x::Scale, y::Scale) = (factor(x) == factor(y)) && (content(x) == content(y))

chsubblocks(x::Scale, blk::AbstractBlock) = Scale(x.alpha, blk)
cache_key(x::Scale) = (factor(x), cache_key(content(x)))

mat(::Type{T}, x::Scale) where {T} = T(x.alpha) * mat(T, content(x))
mat(::Type{T}, x::Scale{Val{S}}) where {T,S} = T(S) * mat(T, content(x))

function YaoAPI.unsafe_apply!(r::AbstractArrayReg, x::Scale{S}) where {S}
    YaoAPI.unsafe_apply!(r, content(x))
    regscale!(r, factor(x))
    return r
end
function YaoAPI.unsafe_apply!(r::DensityMatrix, x::Scale{S}) where {S}
    YaoAPI.unsafe_apply!(r, content(x))
    regscale!(r, abs2(factor(x)))
    return r
end

function unsafe_getindex(::Type{T}, x::Scale, i::Integer, j::Integer) where T
    return unsafe_getindex(T, content(x), i, j) * factor(x)
end

function unsafe_getcol(::Type{T}, x::Scale, j::DitStr) where T
    locs, vals = unsafe_getcol(T, content(x), j)
    return locs, rmul!(vals, factor(x))
end