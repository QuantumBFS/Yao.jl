"""
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
"""
BInt = Int64
DInt = Int64

basis(num_bit::Int) = collect(0:1<<num_bit-1)

########## BitArray views ###################
import Base: BitArray
function bitarray(v::Vector{T}) where T<:Number
    xdim = sizeof(eltype(v))*8
    #ba = BitArray{2}(0, 0)
    ba = BitArray(0, 0)
    ba.chunks = reinterpret(UInt64, v)
    ba.dims = (xdim, length(v))
    ba.len = xdim*length(v)
    return ba
end

function bitarray(v::Vector{UInt64})
    #ba = BitArray{2}(0, 0)
    ba = BitArray(undef, (0, 0))
    ba.chunks = v
    ba.dims = (64, length(v))
    ba.len = 64*length(v)
    return ba
end
bitarray(v::Number) = bitarray([v])

########## Bit-Wise Operations ##############
Ints = Union{Vector{Int}, Int}
Intsu = Union{Ints, UnitRange{Int}}
DInts = Union{Vector{DInt}, DInt}
bmask(ibit::Int) = one(DInt) << (ibit-1)
bmask(ibit::Vector{Int}) = reduce(+, [one(DInt) << b for b in (ibit.-1)])
bmask(bits::UnitRange{Int}) = ((one(DInt) << (bits.stop - bits.start + 1)) - one(DInt)) << (bits.start-1)

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

# take a bit/bits
takebit(indices::DInts, ibit::Int) = @. (indices >> (ibit-1)) & 1
takebit(indices::DInt, ibit::Vector{Int}) = @. (indices .>> (ibit-1)) & 1
# a position is 1?
testbit(indices::DInts, ibit::Int) = @. (indices & bmask(ibit)) != 0
testbit(indices::DInt, ibit::Vector{Int}) = @. (indices & bmask(ibit)) != 0

# set a bit
setbit(indices::DInts, ibit::Intsu) = indices .| bmask(ibit)
setbit!(indices::DInts, ibit::Intsu) = indices[:] |= bmask(ibit)

# flip a bit/bits
flip(indices::DInts, ibit::Intsu) = xor.(indices, bmask(ibit))
flip!(indices::DInts, ibit::Intsu) = indices[:] = xor.(indices, bmask(ibit))
# flip all bits
flip(indices::DInts) = ~indices
flip!(indices::DInts) = indices[:] = ~indices

# swap two bits
function swapbits(num::DInts, i::Int, j::Int)
    i = i.-1
    j = j.-1
    k = @. (num >> j) & 1 - (num >> i) & 1
    @. num + k*(1<<i) - k*(1<<j)
end

# utils used in controled bits
function indices_with(num_bit::Int, poss::Vector{Int}, vals::Vector{BInt}, indices::Vector{DInt})
    sls = Vector{Union{Colon, Int}}([Colon() for i=1:num_bit])
    sls[poss] = vals.+1
    getindex(reshape(indices, fill(2, num_bit)...), sls...)
end

"""
subspace spanned by bits placed on given positions.
"""
function _subspace(num_bit::Int, poss::Vector{Int}, base::DInt)
    if length(poss) == 0
        return [base]
    else
        rest, pos = poss[1:end-1], poss[end]
        # efficiency of vcat?
        return vcat(_subspace(num_bit, rest, base), _subspace(num_bit, rest, flip(base, pos)))
    end
end

function indices_with(num_bit::Int, poss::Vector{Int}, vals::Vector{BInt})
    remain_poss = setdiff(1:num_bit, poss)
    _subspace(num_bit, remain_poss, bmask(poss[vals.!=0]))
end

function indices_with2(num_bit::Int, poss::Vector{Int}, vals::Vector{BInt})
    remain_poss = setdiff(1:num_bit, poss)
    bmask(poss)
end

# state utilities
function onehot(x::Int, num_bit::Int)
    v = zeros(Complex128, 1<<num_bit)
    v[x+1] = 1
    return v
end

function ghz(num_bit::Int; x::Int=0)
    v = zeros(Complex128, 1<<num_bit)
    v[x+1] = 1/sqrt(2)
    v[flip(x, collect(1:num_bit))+1] = 1/sqrt(2)
    return v
end
