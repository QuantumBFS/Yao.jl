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
    ba = BitArray(undef, (0, 0))
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
DInts = Union{Vector{DInt}, DInt}
pos_mask(ibit::Int) = 1 << (ibit-1)
pos_mask(ibit::Vector{Int}) = reduce(+, [1 << b for b in (ibit.-1)])

# take a bit/bits
takebit(indices::DInts, ibit::Int) = (indices .>> (ibit-1)) .& 1
takebit(indices::DInt, ibit::Vector{Int}) = (indices .>> (ibit.-1)) .& 1

# set a bit
set(indices::DInts, ibit::Ints) = indices .| pos_mask(ibit)
set!(indices::DInts, ibit::Ints) = indices[:] |= pos_mask(ibit)

# flip a bit/bits
flip(indices::DInts, ibit::Ints) = xor.(indices, pos_mask(ibit))
flip!(indices::DInts, ibit::Ints) = indices[:] = xor.(indices, pos_mask(ibit))
# flip all bits
flip(indices::DInts) = ~indices
flip!(indices::DInts) = indices[:] = ~indices

# utils used in controled bits
function indices_with(num_bit::Int, poss::Vector{Int}, vals::Vector{BInt}, indices::Vector{DInt})
    sls = Vector{Union{Colon, Int}}([Colon() for i=1:num_bit])
    sls[poss] = vals.+1
    getindex(reshape(indices, fill(2, num_bit)...), sls...)[:]
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
    _subspace(num_bit, remain_poss, pos_mask(poss[vals.!=0]))
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
