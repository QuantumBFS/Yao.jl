export @bit_str

"""
    BitStr

String literal for qubits.
"""
struct BitStr <: AbstractString
    val::UInt
    len::Int
end

BitStr(str::String) = BitStr(bitstring2int(str), length(str))

# use system interface
asindex(bits::BitStr) = bits.val + 1
length(bits::BitStr) = bits.len

"""
    @bit_str -> BitStr

Construct a bit string. such as `bit"0000"`. The bit strings also supports string concat. Just use
it like normal strings.
"""
macro bit_str(str)
    @assert length(str) < 64 "we do not support large integer at the moment"
    BitStr(str)
end

function bitstring2int(str::String)
    val = unsigned(0)
    for (k, each) in enumerate(reverse(str))
        if each == '1'
            val += 0x01 << (k - 1)
        elseif each == '0'
            continue
        else
            throw(InexactError(:bitstring2int, BitStr, str))
        end
    end
    val
end


Base.:*(lhs::BitStr, rhs::BitStr) = BitStr(string(lhs.val, base=2, pad=lhs.len) * bin(rhs.val, base=2, pad=rhs.len))

function Base.repeat(s::BitStr, n::Integer)
    val = s.val
    for i in 1:n-1
        val += s.val << (s.len * i)
    end
    BitStr(val, n * s.len)
end

function Base.show(io::IO, bitstr::BitStr)
    print(io, string(bitstr.val, base=2, pad=bitstr.len))
end

# function register(::Type{T}, bits::BitStr, nbatch::Int) where T
#     st = zeros(T, 1 << length(bits), nbatch)
#     st[asindex(bits), :] .= 1
#     register(st)
# end

# """
#     register([type], bit_str, [nbatch=1]) -> DefaultRegister

# Returns a [`DefaultRegister`](@ref) by inputing a bit string, e.g

# ```@repl
# using Yao
# register(bit"0000")
# ```
# """
# register(bits::BitStr, nbatch::Int=1) = register(DefaultType, bits, nbatch)
