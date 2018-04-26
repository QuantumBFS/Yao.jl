# Integer Logrithm of 2
# Ref: https://stackoverflow.com/questions/21442088
export log2i

"""
    log2i(x)

logrithm for integers
"""
function log2i(x::T)::T where {T <: Integer}
    log2i(unsigned(x))
end

function log2i(x::UInt8)::UInt8
    t::UInt8 = UInt8(x > 0xf)    << 2; x >>= t
    s::UInt8 = UInt8(x > 0x3)    << 1; x >>= s; t |= s;
    (t | (x >> 1))
end

function log2i(x::UInt16)::UInt16
    t::UInt16 = UInt16(x > 0xff)   << 3; x >>= t
    s::UInt16 = UInt16(x > 0xf)    << 2; x >>= s; t |= s;
    s = (x > 0x3)    << 1; x >>= s; t |= s;
    (t | (x >> 1))
end

function log2i(x::UInt32)::UInt32
    t::UInt32 = UInt32(x > 0xffff) << 4; x >>= t
    s::UInt32 = UInt32(x > 0xff)   << 3; x >>= s; t |= s;
    s = UInt32(x > 0xf)    << 2; x >>= s; t |= s;
    s = UInt32(x > 0x3)    << 1; x >>= s; t |= s;
    (t | (x >> 1))
end

function log2i(x::UInt64)::UInt64
    t::UInt64 = UInt64(x > 0xffff_ffff) << 5; x >>= t
    s::UInt64 = UInt64(x > 0xffff)     << 4; x >>= s; t |= s;
    s = UInt64(x > 0xff)       << 3; x >>= s; t |= s;
    s = UInt64(x > 0xf)        << 2; x >>= s; t |= s;
    s = UInt64(x > 0x3)        << 1; x >>= s; t |= s;
    (t | (x >> 1))
end

function log2i(x::UInt128)::UInt128
    t::UInt128 = UInt128(x > 0xffff_ffff_ffff_ffff) << 6; x >>= t
    s::UInt128 = UInt128(x > 0xffff_ffff)           << 5; x >>= s; t |= s;
    s = UInt128(x > 0xffff)                << 4; x >>= s; t |= s;
    s = UInt128(x > 0xff)                  << 3; x >>= s; t |= s;
    s = UInt128(x > 0xf)                   << 2; x >>= s; t |= s;
    s = UInt128(x > 0x3)                   << 1; x >>= s; t |= s;
    (t | (x >> 1))
end
