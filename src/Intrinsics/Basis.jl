const DInt = Int
const Ints{IT} = Union{NTuple{<:Any, IT}, Vector{IT}, IT, UnitRange{IT}} where IT<:Integer
"""
    basis([IntType], num_bit::Int) -> UnitRange{IntType}
    basis([IntType], state::AbstractArray) -> UnitRange{IntType}

Returns the UnitRange for basis in Hilbert Space of num_bit qubits.
If an array is supplied, it will return a basis having the same size with the first diemension of array.
"""
basis(arg::Union{Int, AbstractArray}) = basis(DInt, arg)
basis(::Type{Ti}, num_bit::Int) where Ti<:Integer = UnitRange{Ti}(0, 1<<num_bit-1)
basis(::Type{Ti}, state::AbstractArray) where Ti<:Integer = UnitRange{Ti}(0, size(state, 1)-1)


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
    ba = BitArray(undef, 0, 0)
    ba.len = 64*length(v)
    ba.chunks = UInt64.(v)
    ba.dims = (64, length(v))
    view(ba, 1:num_bit, :)
end

function bitarray(v::Vector{T})::BitArray{2} where T<:Union{UInt64, Int64}
    #ba = BitArray{2}(0, 0)
    ba = BitArray(undef, 0, 0)
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
packbits(arr::AbstractVector) = _packbits(arr)[]
packbits(arr::AbstractArray) = _packbits(arr)
_packbits(arr) = selectdim(sum(mapslices(x -> x .* (1 .<< (0:size(arr, 1)-1)), arr, dims=1), dims=1), 1, 1)

# different view points of qubits
"""
    bfloat(b::Integer; nbit::Int=bit_length(b)) -> Float64

float view, with big end qubit 1.
"""
bfloat(b::Integer; nbit::Int=bit_length(b)) = breflect(nbit, b) / (1<<nbit)

"""
    bfloat_r(b::Integer; nbit::Int) -> Float64

float view, with bits read in inverse order.
"""
bfloat_r(b::Integer; nbit::Int) = b / (1<<nbit)

"""
    bint(b; nbit=nothing) -> Int

integer view, with little end qubit 1.
"""
bint(b::Integer; nbit=nothing) = b
bint(x::Float64; nbit::Int) = breflect(nbit,bint_r(x, nbit=nbit))

"""
    bint_r(b; nbit::Int) -> Integer

integer read in inverse order.
"""
bint_r(b::Integer; nbit::Int) = breflect(nbit, b)
bint_r(x::Float64; nbit::Int) = Int(round(x * (1<<nbit)))

########## Bit-Wise Operations ##############
"""
    bmask([IntType], ibit::Int...) -> IntType
    bmask([IntType], bits::UnitRange{Int}) ->IntType

Return an integer with specific position masked, which is offten used as a mask for binary operations.
"""
function bmask end

bmask(args...) = bmask(DInt, args...)
bmask(::Type{Ti}) where Ti<:Integer = Ti(0)
function bmask(::Type{Ti}, ibit::Int...)::Ti where Ti<:Integer
    reduce(+, [Ti(1) << (b-1) for b in ibit])
end
function bmask(::Type{Ti}, bits::UnitRange{Int})::Ti where Ti<:Integer
    ((Ti(1) << (bits.stop - bits.start + 1)) - Ti(1)) << (bits.start-1)
end

"""
    baddrs(b::Integer) -> Vector

get the locations of nonzeros bits, i.e. the inverse operation of bmask.
"""
function baddrs(b::Integer)
    locs = Vector{Int}(undef, count_ones(b))
    k = 1
    for i = 1:bit_length(b)
        if takebit(b, i) == 1
            locs[k] = i
            k += 1
        end
    end
    locs
end

"""
    takebit(index::Integer, bits::Int...) -> Int

Return a bit(s) at specific position.
"""
takebit(index::Ti, ibit::Int) where Ti<:Integer = (index >> (ibit-1)) & one(Ti)
@inline function takebit(index::Ti, bits::Int...) where Ti<:Integer
    res = Ti(0)
    for (i, ibit) in enumerate(bits)
        res += takebit(index, ibit) << (i-1)
    end
    res
end

"""
    testany(index::Integer, mask::Integer) -> Bool

Return true if any masked position of index is 1.
"""
testany(index::Ti, mask::Ti) where Ti<:Integer = (index & mask) != zero(Ti)

"""
    testall(index::Integer, mask::Integer) -> Bool

Return true if all masked position of index is 1.
"""
testall(index::Ti, mask::Ti) where Ti<:Integer = (index & mask) == mask

"""
    testval(index::Integer, mask::Integer, onemask::Integer) -> Bool

Return true if values at positions masked by `mask` with value 1 at positions masked by `onemask` and 0 otherwise.
"""
testval(index::Ti, mask::Ti, onemask::Ti) where Ti<:Integer = index&mask==onemask

"""
    setbit(index::Integer, mask::Integer) -> Integer

set the bit at masked position to 1.
"""
setbit(index::Ti, mask::Ti) where Ti<:Integer = index | mask

"""
    flip(index::Integer, mask::Integer) -> Integer

Return an Integer with bits at masked position flipped.
"""
flip(index::Ti, mask::Ti) where Ti<:Integer = index ⊻ mask

"""
    neg(index::Integer, num_bit::Int) -> Integer

Return an integer with all bits flipped (with total number of bit `num_bit`).
"""
neg(index::Ti, num_bit::Int) where Ti<:Integer = bmask(Ti, 1:num_bit) ⊻ index

"""
    swapbits(num::Integer, mask12::Integer) -> Integer

Return an integer with bits at `i` and `j` flipped.
"""
@inline function swapbits(b::Ti, mask12::Ti) where Ti<:Integer
    bm = b&mask12
    if bm!=0 && bm!=mask12
        b ⊻= mask12
    end
    b
end

"""
    breflect(num_bit::Int, b::Integer[, masks::Vector{Integer}]) -> Integer

Return left-right reflected integer.
"""
function breflect end

@inline function breflect(num_bit::Int, b::Ti)::Ti where Ti<:Integer
    @simd for i in 1:num_bit÷2
        b = swapbits(b, bmask(Ti, i, num_bit-i+1))
    end
    b
end

@inline function breflect(num_bit::Int, b::Ti, masks::Vector{Ti})::Ti where Ti<:Integer
    @simd for m in masks
        b = swapbits(b, m)
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
    filter(x::DInt->testval(x, mask, onemask), basis(num_bit))
end

"""
    bsizeof(x) -> Int

Return the size of object, in number of bit.
"""
bsizeof(x)::Int = sizeof(x) << 3

"""
    bdistance(i::Integer, j::Integer) -> Int

Return number of different bits.
"""
bdistance(i::Ti, j::Ti) where Ti<:Integer = count_ones(i⊻j)

"""
    onehotvec(::Type{T}, num_bit::Int, x::Integer) -> Vector{T}

one-hot wave vector.
"""
function onehotvec(::Type{T}, num_bit::Int, x::Integer) where T
    v = zeros(T, 1<<num_bit)
    v[x+1] = 1
    v
end

"""
    controller(cbits, cvals) -> Function

Return a function that test whether a basis at `cbits` takes specific value `cvals`.
"""
function controller(cbits::Ints{Int}, cvals::Ints{Int})
    do_mask = bmask(cbits...)
    onemask = length(cvals)==0 ? 0 : mapreduce(xy -> (xy[2]==1 ? 1<<(xy[1]-1) : 0), |, zip(cbits, cvals))
    return b->testval(b, do_mask, onemask)
end

struct Reorderer{N}
    orders::Vector{Int}
    taker::Vector{Int}
    differ::Vector{Int}
end

"""Reordered Basis"""
reordered_basis(nbit::Int, orders::Vector{Int}) = Reorderer{nbit}(orders, bmask.(orders), (1:nbit).-orders)

function Base.iterate(it::Reorderer{N}, state=0) where N
    if state == 1<<N
        nothing
    else
        _reorder(state, it.taker, it.differ), state+1
    end
end

Base.eltype(::Reorderer) = Int
Base.length(::Reorderer{N}) where N = 1<<N
Base.size(::Reorderer{N}) where N = 1<<N

@inline function _reorder(b::Int, taker::Vector{Int}, differ::Vector{Int})::Int
    out::Int = 0
    @simd for i = 1:length(differ)
        @inbounds out += (b&taker[i]) << differ[i]
    end
    out
end

function reorder(v::AbstractVector, orders)
    nbit = length(orders)
    nbit == length(v) |> log2i || throw(DimensionMismatch("size of array not match length of order"))
    nv = similar(v)
    taker, differ = bmask.(orders), (1:nbit).-orders

    for b in basis(nbit)
        @inbounds nv[b+1] = v[_reorder(b, taker, differ)+1]
    end
    nv
end

function reorder(A::Union{Matrix, SparseMatrixCSC}, orders)
    M, N = size(A)
    nbit = M|>log2i
    od = [1+b for b in reordered_basis(nbit, orders)]
    od = od |> invperm
    A[od, od]
end
