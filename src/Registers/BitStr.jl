struct QuBitStr
    val::UInt
    len::Int
end

# use system interface
asindex(bits::QuBitStr) = bits.val + 1
length(bits::QuBitStr) = bits.len

macro bit_str(str)
    @assert length(str) < 64 "we do not support large integer at the moment"
    val = unsigned(0)
    for (k, each) in enumerate(reverse(str))
        if each == '1'
            val += 1 << (k - 1)
        end
    end
    QuBitStr(val, length(str))
end

function show(io::IO, bitstr::QuBitStr)
    print(io, "QuBitStr(", bitstr.val, ", ", bitstr.len, ")")
end


function register(::Type{RT}, ::Type{T}, bits::QuBitStr, nbatch::Int) where {RT, T}
    st = zeros(T, 1 << length(bits), nbatch)
    st[asindex(bits), :] .= 1
    register(RT, st, nbatch)
end

function register(bits::QuBitStr, nbatch::Int=1)
    register(DefaultRegister, DefaultType, bits, nbatch)
end
