import Base: repeat

"""
    QuBitStr

String literal for qubits.
"""
struct QuBitStr <: AbstractString
    val::UInt
    len::Int
end

QuBitStr(str::String) = QuBitStr(bitstring2int(str), length(str))

# use system interface
asindex(bits::QuBitStr) = bits.val + 1
length(bits::QuBitStr) = bits.len

"""
    @bit_str -> QuBitStr

Construct a bit string. such as `bit"0000"`. The bit strings also supports string concat. Just use
it like normal strings.
"""
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


import Base: *, repeat
(*)(lhs::QuBitStr, rhs::QuBitStr) = QuBitStr(string(lhs.val, base=2, pad=lhs.len) * bin(rhs.val, base=2, pad=rhs.len))

function repeat(s::QuBitStr, n::Integer)
    val = s.val
    for i in 1:n-1
        val += s.val << (s.len * i)
    end
    QuBitStr(val, n * s.len)
end

function show(io::IO, bitstr::QuBitStr)
    print(io, string(bitstr.val, base=2, pad=bitstr.len))
end

function register(::Type{T}, bits::QuBitStr, nbatch::Int) where T
    st = zeros(T, 1 << length(bits), nbatch)
    st[asindex(bits), :] .= 1
    register(st)
end

"""
    register([type], bit_str, [nbatch=1]) -> DefaultRegister

Returns a [`DefaultRegister`](@ref) by inputing a bit string, e.g

```@repl
using Yao
register(bit"0000")
```
"""
register(bits::QuBitStr, nbatch::Int=1) = register(DefaultType, bits, nbatch)
