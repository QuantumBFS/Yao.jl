import Base: repeat

struct QuBitStr
    val::UInt
    len::Int
end

QuBitStr(str::String) = QuBitStr(bitstring2int(str), length(str))

# use system interface
asindex(bits::QuBitStr) = bits.val + 1
length(bits::QuBitStr) = bits.len

macro bit_str(str)
    @assert length(str) < 64 "we do not support large integer at the moment"
    QuBitStr(str)
end

function bitstring2int(str::String)
    val = unsigned(0)
    for (k, each) in enumerate(reverse(str))
        if each == '1'
            val += 0x01 << (k - 1)
        end
    end
    val
end


import Base: *
(*)(lhs::QuBitStr, rhs::QuBitStr) = QuBitStr(bin(lhs.val, lhs.len) * bin(rhs.val, rhs.len))

function show(io::IO, bitstr::QuBitStr)
    print(io, "QuBitStr(", bitstr.val, ", ", bitstr.len, ")")
end


function register(::Type{T}, bits::QuBitStr, nbatch::Int) where T
    st = zeros(T, 1 << length(bits), nbatch)
    st[asindex(bits), :] .= 1
    register(st)
end

register(bits::QuBitStr, nbatch::Int=1) = register(DefaultType, bits, nbatch)
