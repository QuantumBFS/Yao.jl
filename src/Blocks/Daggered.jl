export Daggered
"""
    Daggered{N, T, BT} <: TagBlock{N, T}

    Daggered(blk::BT)
    Daggered{N, T, BT}(blk)

Daggered Block.
"""
struct Daggered{N, T, BT} <: TagBlock{N, T}
    block::BT
end
Daggered(blk::BT) where {N, T, BT<:MatrixBlock{N, T}} = Daggered{N, T, BT}(blk)

parent(blk::Daggered) = blk.block

adjoint(blk::MatrixBlock) = ishermitian(blk) ? blk : Daggered(blk)
adjoint(blk::Daggered) = blk.block
# sometimes, using daggered cached blocks can be inefficient, we leave this problem to users.
# adjoint(blk::CachedBlock) = CachedBlock(blk.server, adjoint(blk.block), blk.level)

mat(blk::Daggered) = mat(blk.block)'

# take care of hash_key method!
similar(c::Daggered, level::Int) = Daggered(similar(c.block))
copy(c::Daggered, level::Int) = Daggered(copy(c.block))

function print_block(io::IO, c::Daggered)
    print_block(io, c.block)
    print(io, " (Daggered)")
end
