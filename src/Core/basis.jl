#=
DEFINE
---------------------
binary basis is 0000 - 1111
digital basis is 0 - (2^n-1)
qubit counting is 1 - n

FORMAT (should be)
---------------------
binary basis: Bool
digital basis: UInt64
bit counting: Int
=#
using Compat: ComplexF64
const BInt = Int
const DInt = Int

basis(num_bit::Int) = UnitRange{DInt}(0, 1<<num_bit-1)

########## BitArray views ###################
import Base: BitArray
function bitarray(v::Vector{T}) where T<:Number
    xdim = sizeof(eltype(v))*8
    #ba = BitArray{2}(0, 0)
    ba = BitArray(0, 0)
    ba.chunks = reinterpret(DInt, v)
    ba.dims = (xdim, length(v))
    ba.len = xdim*length(v)
    return ba
end

function bitarray(v::Vector{DInt})
    ba = BitArray{2}(0, 0)
    #ba = BitArray(undef, (0, 0))
    ba.chunks = v
    ba.dims = (64, length(v))
    ba.len = 64*length(v)
    return ba
end
bitarray(v::Number) = bitarray([v])

########## Bit-Wise Operations ##############
const Ints = Union{Vector{Int}, Int, UnitRange{Int}}
const DInts = Union{Vector{DInt}, DInt, UnitRange{DInt}}
bmask(ibit::Int...)::Int = sum([one(DInt) << (b-1) for b in ibit])
bmask(bits::UnitRange{Int})::Int = ((one(DInt) << (bits.stop - bits.start + 1)) - one(DInt)) << (bits.start-1)

# bit size
bsizeof(x) = sizeof(x) << 3
function bit_length(x::DInt)
    local n = 0
    while x!=0
        n += 1
        x >>= 1
    end
    return n
end

function log2i(x::T)::T where T
    local n::T = 0
    while x&0x1!=1
        n += 1
        x >>= 1
    end
    return n
end


# take a bit/bits
takebit(index::DInt, ibit::Int)::DInt = (index >> (ibit-1)) & one(DInt)
# a position is 1?
testany(index::DInt, mask::DInt)::Bool = (index & mask) != zero(DInt)
testall(index::DInt, mask::DInt)::Bool = (index & mask) == mask
testval(index::DInt, mask::DInt, onemask::DInt)::Bool = index&mask==onemask

# set a bit
setbit(index::DInt, mask::DInt)::DInt = indices | mask
setbit!(indices::DInts, mask::DInt) = indices[:] |= mask

# flip a bit/bits
flip(index::DInt, mask::DInt)::DInt = index ⊻ mask
flip!(indices::DInt, mask::DInt) = indices[:] = indices .⊻ mask
# flip all bits
neg(index::DInt, num_bit::Int)::DInt = bmask(1:num_bit) ⊻ index

# swap two bits
function swapbits(num::DInt, i::Int, j::Int)::DInt
    i = i-1
    j = j-1
    k = (num >> j) & 1 - (num >> i) & 1
    num + k*(1<<i) - k*(1<<j)
end
swapbits!(bss::Vector{DInt}, i::Int, j::Int) = bss[:] = swapbits.(bss, i, j)

function indices_with(num_bit::Int, poss::Vector{Int}, vals::Vector{BInt})::Vector{DInt}
    mask = bmask(poss...)
    onemask = bmask(poss[vals.!=0]...)
    filter(testval(mask, onemask), basis(num_bit))
end

#################### Array Operation: Roll Axis #######################
# move 1st dim to last
function lrollaxis2!(vec::AbstractArray)
    n = length(vec)
    halfn = n >> 1
    temp = vec[2:2:n]
    vec[1:halfn] = vec[1:2:n]
    vec[halfn+1:end] = temp
    vec
end

# move last dim to 1st
function rrollaxis2!(vec::AbstractArray)
    n = length(vec)
    halfn = n >> 1
    temp = vec[halfn+1:end]
    vec[1:2:n] = vec[1:halfn]
    vec[2:2:n] = temp
    vec
end

function rollaxis2!(v::AbstractArray, k::Int)
    if k > 0
        for i=1:k
            lrollaxis2!(v)
        end
    else
        for i=1:-k
            rrollaxis2!(v)
        end
    end
    v
end

###################### State Utilities ########################
function onehot(num_bit::Int, x::DInt)
    v = zeros(ComplexF64, 1<<num_bit)
    v[x+1] = 1
    return v
end

function ghz(num_bit::Int; x::DInt=DInt(0))
    v = zeros(ComplexF64, 1<<num_bit)
    v[x+1] = 1/sqrt(2)
    v[flip(x, bmask(1:num_bit))+1] = 1/sqrt(2)
    return v
end