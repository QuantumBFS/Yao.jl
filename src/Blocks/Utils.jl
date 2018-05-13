import Base: ismatch
# Size Type
abstract type SizeType end

struct AnySize <: SizeType end
struct GreaterThan{N} <: SizeType end

"""
    ismatch(size, sz) -> Bool

Check whether `sz` matches given `size`.
"""
is_size_match(::Type{T}, sz) where {T <: SizeType} = false
is_size_match(sz, ::Type{T}) where {T <: SizeType} = is_size_match(T, sz)
is_size_match(sza::Int, szb::Int) = sza == szb

is_size_match(::Type{AnySize}, sz::Int) = true
is_size_match(::Type{GreaterThan{N}}, sz::Int) where N = sz > N
is_size_match(::Type{AnySize}, ::Type{T}) where {T <: SizeType} = true
