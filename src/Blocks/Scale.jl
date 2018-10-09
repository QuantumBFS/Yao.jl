export Scale, Pos, Neg, Im, _Im, scale, getscale
"""
    Scale{X, N, T, BT} <: TagBlock{N, T}

    Scale{X}(blk::MatrixBlock)
    Scale{X, N, T, BT}(blk::MatrixBlock)

Scale Block, by a factor of X, notice X is static!
"""
struct Scale{X, BT, N, T} <: TagBlock{N, T}
    block::BT
end
Scale{X}(blk::BT) where {X, N, T, BT<:MatrixBlock{N, T}} = Scale{X, BT, N, T}(blk)

==(b1::Scale{X}, b2::Scale{X}) where X = parent(b1) == parent(b2)
==(b1::Scale{1}, b2::MatrixBlock) where X = parent(b1) == b2
==(b1::MatrixBlock, b2::Scale{1}) where X = b1 == parent(b2)
scale(blk::Scale{X}, x::Number) where X = Scale{X*x}(parent(blk))
scale(blk::MatrixBlock, x::Number) = Scale{x}(blk)
scale(x::Number) = blk -> scale(blk, x)
getscale(blk::Scale{X}) where X = X

# since adjoint can propagate, this way is better
adjoint(blk::Scale{X}) where X = Scale{X'}(adjoint(blk.block))

mat(blk::Scale{X}) where X = X*mat(blk.block)
apply!(reg::AbstractRegister, blk::Scale{X}) where X = X*apply!(reg, blk.block)

# take care of hash_key method!
similar(c::Scale{X}) where X = Scale{X}(similar(c.block))
copy(c::Scale{X}) where X = Scale{X}(copy(c.block))
chblock(pb::Scale{X}, blk::MatrixBlock) where {X} = Scale{X}(blk)

*(x::Number, blk::MatrixBlock) = scale(blk, x)
*(x::Number, blk::Scale{X}) where X = scale(blk, x)
*(blk::MatrixBlock, x::Number) = scale(blk, x)

function *(g1::Scale{X1}, g2::Scale{X2}) where {X1, X2}
    scale(parent(g1)*parent(g2), X1*X2)
end

function *(g1::Scale{X1}, g2::MatrixBlock) where {X1}
    scale(parent(g1)*g2, X1)
end
function *(g2::MatrixBlock, g1::Scale{X1}) where {X1}
    scale(g2*parent(g1), X1)
end

function print_block(io::IO, c::Scale{X}) where X
    printstyled(io, "[$X] "; bold=true, color=:yellow)
    print_block(io, c.block)
end


const Pos{BT, N, T} = Scale{1+0im, BT, N, T}
const Neg{BT, N, T} = Scale{-1+0im, BT, N, T}
const Im{BT, N, T} = Scale{1im, BT, N, T}
const _Im{BT, N, T} = Scale{-1im, BT, N, T}

-(blk::MatrixBlock) = (-1+0im)*blk
-(blk::Neg) = blk.block

function print_block(io::IO, c::Pos)
    printstyled(io, "[+] "; bold=true, color=:yellow)
    print_block(io, c.block)
end

function print_block(io::IO, c::Neg)
    printstyled(io, "[-] "; bold=true, color=:yellow)
    print_block(io, c.block)
end

function print_block(io::IO, c::Im)
    printstyled(io, "[i] "; bold=true, color=:yellow)
    print_block(io, c.block)
end

function print_block(io::IO, c::_Im)
    printstyled(io, "[-i] "; bold=true, color=:yellow)
    print_block(io, c.block)
end
