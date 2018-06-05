const DInt = Int
const Ints = Union{Vector{Int}, Int, UnitRange{Int}}
const DInts = Union{Vector{DInt}, DInt, UnitRange{DInt}}

"""
    basis(num_bit::Int) = UnitRange{Int}

Returns the UnitRange for basis in Hilbert Space of num_bit qubits.
"""
basis(num_bit::Int) = UnitRange{DInt}(0, 1<<num_bit-1)
basis(state::AbstractArray)::UnitRange{DInt} = UnitRange{DInt}(0, size(state, 1)-1)


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
"""
    bmask(ibit::Int...) -> Int
    bmask(bits::UnitRange{Int}) ->Int

Return an integer with specific position masked, which is offten used as a mask for binary operations.
"""
function bmask end

bmask(ibit::Int...)::DInt = sum([one(DInt) << (b-1) for b in ibit])
bmask(bits::UnitRange{Int})::DInt = ((one(DInt) << (bits.stop - bits.start + 1)) - one(DInt)) << (bits.start-1)

"""
    takebit(index::Int, ibit::Int) -> Int

Return a bit at specific position.
"""
takebit(index::DInt, ibit::Int)::DInt = (index >> (ibit-1)) & one(DInt)

"""
    testany(index::Int, mask::Int) -> Bool

Return true if any masked position of index is 1.
"""
testany(index::DInt, mask::DInt)::Bool = (index & mask) != zero(DInt)

"""
    testall(index::Int, mask::Int) -> Bool

Return true if all masked position of index is 1.
"""
testall(index::DInt, mask::DInt)::Bool = (index & mask) == mask

"""
    testval(index::Int, mask::Int, onemask::Int) -> Bool

Return true if values at positions masked by `mask` with value 1 at positions masked by `onemask` and 0 otherwise.
"""
testval(index::DInt, mask::DInt, onemask::DInt)::Bool = index&mask==onemask

"""
    setbit(index::Int, mask::Int) -> Int

set the bit at masked position to 1.
"""
setbit(index::DInt, mask::DInt)::DInt = indices | mask

"""
    flip(index::Int, mask::Int) -> Int

Return an Integer with bits at masked position flipped.
"""
flip(index::DInt, mask::DInt)::DInt = index ⊻ mask

"""
    neg(index::Int, num_bit::Int) -> Int

Return an integer with all bits flipped (with total number of bit `num_bit`).
"""
neg(index::DInt, num_bit::Int)::DInt = bmask(1:num_bit) ⊻ index

"""
    swapbits(num::Int, mask12::Int) -> Int

Return an integer with bits at `i` and `j` flipped.
"""
function swapbits(b::Int, mask12::Int)::Int
    bm = b&mask12
    if bm!=0 && bm!=mask12
        b ⊻= mask12
    end
    b
end

"""
    indices_with(num_bit::Int, poss::Vector{Int}, vals::Vector{Int}) -> Vector{Int}

Return indices with specific positions `poss` with value `vals` in a hilbert space of `num_bit` qubits.
"""
function indices_with(num_bit::Int, poss::Vector{Int}, vals::Vector{Int})::Vector{DInt}
    mask = bmask(poss...)
    onemask = bmask(poss[vals.!=0]...)
    filter(x->testval(x, mask, onemask), basis(num_bit))
end
