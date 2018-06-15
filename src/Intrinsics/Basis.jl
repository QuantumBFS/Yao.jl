const DInt = Int
const Ints = Union{Vector{Int}, Int, UnitRange{Int}}
const DInts = Union{Vector{DInt}, DInt, UnitRange{DInt}}
"""
    basis(num_bit::Int) -> UnitRange{Int}
    basis(state::AbstractArray) -> UnitRange{Int}

Returns the UnitRange for basis in Hilbert Space of num_bit qubits.
If an array is supplied, it will return a basis having the same size with the first diemension of array.
"""
basis(num_bit::Int) = UnitRange{DInt}(0, 1<<num_bit-1)
basis(state::AbstractArray)::UnitRange{DInt} = UnitRange{DInt}(0, size(state, 1)-1)


########## BitArray views ###################
import Base: BitArray
"""
    bitarray(v::Vector, [num_bit::Int]) -> BitArray
    bitarray(v::Int, num_bit::Int) -> BitArray
    bitarray(num_bit::Int) -> Function

Construct BitArray from an integer vector, if num_bit not supplied, it is 64.
If an integer is supplied, it returns a function mapping a Vector/Int to bitarray.
"""
function bitarray(v::Vector{T}, num_bit::Int)::BitArray{2} where T<:Number
    #ba = BitArray{2}(0, 0)
    ba = BitArray(0, 0)
    ba.len = 64*length(v)
    ba.chunks = UInt64.(v)
    ba.dims = (64, length(v))
    view(ba, 1:num_bit, :)
end

function bitarray(v::Vector{T})::BitArray{2} where T<:Union{UInt64, Int64}
    #ba = BitArray{2}(0, 0)
    ba = BitArray(0, 0)
    ba.len = 64*length(v)
    ba.chunks = reinterpret(UInt64, v)
    ba.dims = (64, length(v))
    ba
end

bitarray(v::Number, num_bit::Int)::BitArray{1} = vec(bitarray([v], num_bit))
bitarray(nbit::Int) = x->bitarray(x, nbit)

"""
    packbits(arr::AbstractArray) -> AbstractArray

pack bits to integers, usually take a BitArray as input.
"""
packbits(arr::AbstractArray) = slicedim(sum(mapslices(x -> x .* (1 .<< (0:size(arr, 1)-1)), arr, 1), 1), 1, 1)

########## Bit-Wise Operations ##############
"""
    bmask(ibit::Int...) -> Int
    bmask(bits::UnitRange{Int}) ->Int

Return an integer with specific position masked, which is offten used as a mask for binary operations.
"""
function bmask end

bmask() = DInt(0)
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
function swapbits(b::DInt, mask12::DInt)::DInt
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

"""
    bsizeof(x) -> Int

Return the size of object, in number of bit.
"""
bsizeof(x)::Int = sizeof(x) << 3

"""
    bdistance(i::DInt, j::DInt) -> Int

Return number of different bits.
"""
bdistance(i::DInt, j::DInt)::Int = count_ones(i⊻j)

"""
    onehotvec(::Type{T}, num_bit::Int, x::DInt) -> Vector{T}

one-hot wave vector.
"""
function onehotvec(::Type{T}, num_bit::Int, x::DInt) where T
    v = zeros(T, 1<<num_bit)
    v[x+1] = 1
    v
end

"""
    controller(cbits, cvals) -> Function

Return a function that test whether a basis at `cbits` takes specific value `cvals`.
"""
function controller(cbits, cvals)
    do_mask = bmask(cbits...)
    onepos = cvals.==1
    onemask = any(onepos) ? bmask(cbits[onepos]...) : 0
    return b->testval(b, do_mask, onemask)
end

struct Reorderer{N}
    orders::Vector{Int}
    taker::Vector{Int}
    differ::Vector{Int}
end

"""Reordered Basis"""
reordered_basis(nbit::Int, orders::Vector{Int}) = Reorderer{nbit}(orders, bmask.(orders), (1:nbit).-orders)

Base.start(ro::Reorderer)::Int = 0
Base.done(ro::Reorderer{N}, state::Int) where N = state == 1<<N
function Base.next(ro::Reorderer, state::Int)::Tuple{Int, Int}
    _reorder(state, ro.taker, ro.differ), state+1
end
Base.eltype(::Reorderer) = Int
Base.eltype(::Type{Reorderer}) = Int
Base.length(::Reorderer{N}) where N = 1<<N
Base.size(::Reorderer{N}) where N = 1<<N
Base.iteratoreltype(::Type{Reorderer}) = Int
Base.iteratorsize(::Type{Reorderer}) = 1<<N

@inline function _reorder(b::Int, taker::Vector{Int}, differ::Vector{Int})::Int
    out::Int = 0
    @simd for i = 1:length(differ)
        @inbounds out += (b&taker[i]) << differ[i]
    end
    out
end
