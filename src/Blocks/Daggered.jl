export Daggered
"""
    Daggered{N, T, BT} <: MatrixBlock{N, T}

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
adjoint(::PuGate) = Pd
adjoint(::PdGate) = Pu

adjoint(blk::ChainBlock) = typeof(blk)(map(adjoint, blocks(blk) |> reverse))
adjoint(blk::KronBlock) = typeof(blk)(blk.slots, blk.addrs, map(adjoint, blk.blocks))

adjoint(blk::CachedBlock) = CachedBlock(blk.server, adjoint(blk.block), blk.level)
adjoint(blk::RotationGate) = RotationGate(blk.U, -blk.theta)
adjoint(blk::ShiftGate) = ShiftGate(-blk.theta)
adjoint(blk::PhaseGate) = PhaseGate(-blk.theta)
adjoint(blk::RepeatedBlock{N}) where N = RepeatedBlock{N}(adjoint(blk.block), blk.addrs)
adjoint(blk::Concentrator{N}) where N = Concentrator{N}(adjoint(blk.block), blk.usedbits)
adjoint(blk::Roller) = Roller(map(adjoint, blk.blocks))
adjoint(blk::ControlBlock{N}) where N = ControlBlock{N}(blk.ctrl_qubits, blk.vals, adjoint(blk.block), blk.addr)
mat(blk::Daggered) = mat(blk.block)'

# take care of hash_key method!
similar(c::Daggered, level::Int) = Daggered(similar(c.block))
copy(c::Daggered, level::Int) = Daggered(copy(c.block))

function print_block(io::IO, c::Daggered)
    print_block(io, c.block)
    print(io, " (Daggered)")
end
