export Scale, Neg, Im, _Im, scale, getscale
"""
    Scale{X, N, T, BT} <: TagBlock{N, T}

    Scale{X}(blk::MatrixBlock)
    Scale{X, N, T, BT}(blk::MatrixBlock)

Scale Block, by a factor of X, notice X is static!
"""
struct Scale{N, T, X, BT} <: TagBlock{N, T}
    block::BT
end
Scale{X}(blk::BT) where {X, N, T, BT<:MatrixBlock{N, T}} = Scale{X, N, T, BT}(blk)

==(b1::Scale{X}, b2::Scale{X}) where X = parent(b1) == parent(b2)
scale(blk::Scale{X}, x::Number) where X = Scale{X*x}(parent(blk))
scale(blk::MatrixBlock, x::Number) = Scale{x}(blk)
getscale(blk::Scale{X}) where X = X

parent(blk::Scale) = blk.block

# since adjoint can propagate, this way is better
adjoint(blk::Scale{X}) where X = Scale{X'}(adjoint(blk.block))

mat(blk::Scale{X}) where X = X*mat(blk.block)
apply!(reg::AbstractRegister, blk::Scale{X}) where X = X*apply!(reg, blk.block)

# take care of hash_key method!
similar(c::Scale{X}, level::Int) where X = Scale{X}(similar(c.block))
copy(c::Scale{X}, level::Int) where X = Scale{X}(copy(c.block))

*(x::Number, blk::MatrixBlock) = scale(blk, x)
*(x::Number, blk::Scale{X}) where X = scale(blk, x)
*(blk::MatrixBlock, x::Number) = scale(blk, x)

function *(g1::Scale{X1, N}, g2::Scale{X2, N}) where {X1, X2, N}
    scale(parent(g1)*parent(g2), X1*X2)
end

function *(g1::Scale{X1, N}, g2::MatrixBlock{N}) where {X1, N}
    scale(parent(g1)*g2, X1)
end
function *(g2::MatrixBlock{N}, g1::Scale{X1, N}) where {X1, N}
    scale(g2*parent(g1), X1)
end

function print_block(io::IO, c::Scale{X}) where X
    print(io, "$X*")
    print_block(io, c.block)
end

"""
    Neg{N, T, BT} = Scale{-1, N, T, BT}

(Neg)ative of Block.
"""
const Neg{N, T, BT} = Scale{-1, N, T, BT}
"""
    Im{N, T, BT} = Scale{1im, N, T, BT}

Mulitply (Im)aginary unit on Block.
"""
Im{N, T, BT} = Scale{1im, N, T, BT}
"""
    _Im{N, T, BT} = Scale{-1im, N, T, BT}

Mulitply (-Im)aginary unit on Block.
"""
const _Im{N, T, BT} = Scale{-1im, N, T, BT}
-(blk::MatrixBlock) = (-1)*blk
-(blk::Neg) = blk.block

function print_block(io::IO, c::Neg)
    print(io, "-")
    print_block(io, c.block)
end

function print_block(io::IO, c::Im)
    print(io, "i")
    print_block(io, c.block)
end

function print_block(io::IO, c::_Im)
    print(io, "-i")
    print_block(io, c.block)
end

