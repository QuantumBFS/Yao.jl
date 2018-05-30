module Basis

export DInt, Ints, DInts
export basis, bmask
export bsizeof, bit_length, log2i
export testall, testany, testval, setbit, flip, neg, swapbits, takebit
export indices_with

"""
    basis(num_bit::Int) = UnitRange{Int}

Returns the UnitRange for basis in Hilbert Space of num_bit qubits.
"""
function basis end


"""
    bmask(ibit::Int...) -> Int
    bmask(bits::UnitRange{Int}) ->Int

Return an integer with specific position masked, which is offten used as a mask for binary operations.
"""
function bmask end

"""
    bsizeof(x) -> Int

Return the size of instance x, in number of bit.
"""
function bsizeof end

"""
    bit_length(x::Int) -> Int

Return the number of bits required to represent input integer x.
"""
function bit_length end

"""
    log2i(x::Integer) -> Integer

Return log2(x), this integer version of `log2` is fast but only valid for number equal to 2^n.
Ref: https://stackoverflow.com/questions/21442088
"""
function log2i end

"""
    takebit(index::Int, ibit::Int) -> Int

Return a bit at specific position.
"""
function takebit end

"""
    testany(index::Int, mask::Int) -> Bool

Return true if any masked position of index is 1.
"""
function testany end

"""
    testall(index::Int, mask::Int) -> Bool

Return true if all masked position of index is 1.
"""
function testall end

"""
    testval(index::Int, mask::Int, onemask::Int) -> Bool

Return true if values at positions masked by `mask` with value 1 at positions masked by `onemask` and 0 otherwise.
"""
function testval end

"""
    setbit(index::Int, mask::Int) -> Int

set the bit at masked position to 1.
"""
function setbit end

"""
    flip(index::Int, mask::Int) -> Int

Return an Integer with bits at masked position flipped.
"""
function flip end

"""
    neg(index::Int, num_bit::Int) -> Int

Return an integer with all bits flipped (with total number of bit `num_bit`).
"""
function neg end

"""
    swapbits(num::Int, i::Int, j::Int) -> Int

Return an integer with bits at `i` and `j` flipped.
"""
function swapbits end

"""
    indices_with(num_bit::Int, poss::Vector{Int}, vals::Vector{Int}) -> Vector{Int}

Return indices with specific positions `poss` with value `vals` in a hilbert space of `num_bit` qubits.
"""
function indices_with end



const DInt = Int
const Ints = Union{Vector{Int}, Int, UnitRange{Int}}
const DInts = Union{Vector{DInt}, DInt, UnitRange{DInt}}

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
bmask(ibit::Int...)::DInt = sum([one(DInt) << (b-1) for b in ibit])
bmask(bits::UnitRange{Int})::DInt = ((one(DInt) << (bits.stop - bits.start + 1)) - one(DInt)) << (bits.start-1)

bsizeof(x)::Int = sizeof(x) << 3

function bit_length(x::DInt)::Int
    local n = 0
    while x!=0
        n += 1
        x >>= 1
    end
    return n
end

function log2i(x::T)::T where T <: Integer
    local n::T = 0
    while x&1!=1
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

# flip a bit/bits
flip(index::DInt, mask::DInt)::DInt = index ⊻ mask
# flip all bits
neg(index::DInt, num_bit::Int)::DInt = bmask(1:num_bit) ⊻ index

# swap two bits
function swapbits(num::DInt, i::Int, j::Int)::DInt
    i = i-1
    j = j-1
    k = (num >> j) & 1 - (num >> i) & 1
    num + k*(1<<i) - k*(1<<j)
end

function indices_with(num_bit::Int, poss::Vector{Int}, vals::Vector{Int})::Vector{DInt}
    mask = bmask(poss...)
    onemask = bmask(poss[vals.!=0]...)
    filter(testval(mask, onemask), basis(num_bit))
end

###################### State Utilities ########################
function onehot(num_bit::Int, x::DInt)
    v = zeros(ComplexF64, 1<<num_bit)
    v[x+1] = 1
    return v
end

function ghz(num_bit::Int; x::DInt=zero(DInt))
    v = zeros(ComplexF64, 1<<num_bit)
    v[x+1] = 1/sqrt(2)
    v[flip(x, bmask(1:num_bit))+1] = 1/sqrt(2)
    return v
end

end
