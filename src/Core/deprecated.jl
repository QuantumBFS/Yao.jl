# utils used in controled bits
"""
subspace spanned by bits placed on given positions.
"""
function _subspace(num_bit::Int, poss::Vector{Int}, base::DInt)
    if length(poss) == 0
        return [base]
    else
        rest, pos = poss[1:end-1], poss[end]
        return vcat(_subspace(num_bit, rest, base), _subspace(num_bit, rest, flip(base, pos)))
    end
end

function ygate(::Type{MT}, num_bit::Int, bits::Ints) where MT<:Complex
    mask = bmask(bits...)
    bss = basis(num_bit)
    order = map(b->flip(b, mask) + 1, basis(num_bit))
    vals = mapreduce(bit->map(b->MT(im)*(2*takebit(b, bit)-MT(1)), bss), (x,y)->broadcast(*,x,y), bits)
    PermuteMultiply(order, vals)
end

function zgate(::Type{MT}, num_bit::Int, bits::Ints) where MT<:Number
    bss = basis(num_bit)
    vals = mapreduce(bit->map(b->MT(1)-2*takebit(b, bit), bss), (x,y)->broadcast(*,x,y), bits)
    Diagonal(vals)
end

function czgate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) where MT<:Number
    Diagonal(map(i->MT(1)-2*(takebit(i, b1) & takebit(i, b2)), basis(num_bit)))
end
function cxgate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) where MT<:Number
    mask = bmask(b1)
    db = b2-b1
    order = map(i->i ⊻ ((i & mask) << db) + 1, basis(num_bit))
    PermuteMultiply(order, ones(MT, 1<<num_bit))
end


