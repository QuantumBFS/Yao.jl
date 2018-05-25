# This file is a part of BitManip.jl, licensed under the MIT License (MIT).


export BitCount
const BitCount = Union{Signed, Unsigned}

function bsizeof end
export bsizeof

function bmask end
export bmask

function lsbmask end
export lsbmask

function msbmask end
export msbmask

function bget end
export bget

function bset end
export bset

function bclear end
export bclear

function bflip end
export bflip

function lsbget end
export lsbget

function msbget end
export msbget


@inline fbc(::Type{T}, x) where T = x%unsigned(T)
@inline fbc(::Type{T}, bits::UnitRange{U}) where {T, U} = fbc(T, bits.start):fbc(T, bits.stop)


@inline bsizeof(x) = sizeof(x) << 3


@inline bmask(::Type{T}, bit::BitCount) where T = one(T) << fbc(T, bit)

@inline bmask(::Type{T}, bits::UnitRange{U}) where {T <: Integer, U <: BitCount} = begin
    fbits = fbc(T, bits)
    #@assert fbits.stop >= fbits.start "Bitmask range of fbits can't be reverse"
    ((one(T) << (fbits.stop - fbits.start + 1)) - one(T)) << fbits.start
end


@inline lsbmask(::Type{T}) where {T <: Integer} = one(T)

@inline msbmask(::Type{T}) where {T <: Integer} = one(T) << fbc(T, bsizeof(T) - 1)


@inline lsbmask(::Type{T}, nbits::BitCount) where {T <: Integer} = ~(~zero(T) << fbc(T, nbits))

@inline msbmask(::Type{T}, nbits::BitCount) where {T <: Integer} = ~(~zero(T) >>> fbc(T, nbits))


@inline bget(x::T, bit::BitCount) where {T <: Integer} = x & bmask(T, fbc(T, bit)) != zero(T)

@inline bset(x::T, bit::BitCount, y::Bool) where {T <: Integer} = y ? bset(x, fbc(T, bit)) : bclear(x, fbc(T, bit))
@inline bset(x::T, bit::BitCount) where {T <: Integer} = x | bmask(typeof(x), fbc(T, bit))

@inline bclear(x::T, bit::BitCount) where {T <: Integer} = x & ~bmask(typeof(x), fbc(T, bit))


@inline bget(x::T, bits::UnitRange{U}) where {T <: Integer, U <: BitCount} = begin
    fbits = fbc(T, bits)
    (x & bmask(typeof(x), fbits)) >>> fbits.start
end

@inline bset(x::T, bits::UnitRange{U}, y::Integer) where {T <: Integer, U <: BitCount} = begin
    fbits = fbc(T, bits)
    local bm = bmask(typeof(x), fbits)
    (x & ~bm) | ((convert(typeof(x), y) << fbits.start) & bm)
end


@inline bflip(x::T, bit::BitCount) where {T <: Integer} = xor(x, bmask(typeof(x), fbc(T, bit)))

@inline bflip(x::T, bits::UnitRange{U}) where {T <: Integer, U <: BitCount} = xor(x, bmask(typeof(x), fbc(T, bits)))


@inline lsbget(x::T) where {T <: Integer} =
    x & lsbmask(typeof(x)) != zero(typeof(x))

@inline msbget(x::T) where {T <: Integer} =
    x & msbmask(typeof(x)) != zero(typeof(x))


@inline lsbget(x::T, nbits::BitCount) where {T <: Integer} =
    x & lsbmask(typeof(x), fbc(T, nbits))

@inline msbget(x::T, nbits::BitCount) where {T <: Integer} =
    x >>> (bsizeof(x) - fbc(T, nbits))
