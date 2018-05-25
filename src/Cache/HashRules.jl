import Base: hash, ==

###################
# Composite Blocks
###################

==(lhs::CompositeBlock, rhs::CompositeBlock) = false

function hash(c::ChainBlock, h::UInt)
    hashkey = hash(object_id(c), h)
    for each in c.blocks
        hashkey = hash(each, hashkey)
    end
    hashkey
end

==(lhs::ChainBlock{N, T}, rhs::ChainBlock{N, T}) where {N, T} = all(lhs.blocks .== rhs.blocks)

# NOTE: kronecker blocks are equivalent if its addrs and blocks is the same
function hash(block::KronBlock{N, T}, h::UInt) where {N, T}
    hashkey = hash(object_id(block), h)

    for (addr, block) in block
        hashkey = hash(addr, hashkey)
        hashkey = hash(block, hashkey)
    end
    hashkey
end

function ==(lhs::KronBlock{N, T}, rhs::KronBlock{N, T}) where {N, T}
    all(lhs.addrs .== rhs.addrs) && all(lhs.blocks .== rhs.blocks)
end

function hash(ctrl::ControlBlock, h::UInt)
    hashkey = hash(object_id(ctrl), h)
    for each in ctrl.ctrl_qubits
        hashkey = hash(each, hashkey)
    end

    hashkey = hash(ctrl.block, hashkey)
    hashkey = hash(ctrl.addr, hashkey)
    hashkey
end

==(lhs::ControlBlock, rhs::ControlBlock) = false
function ==(lhs::ControlBlock{BT, N, T}, rhs::ControlBlock{BT, N, T}) where {BT, N, T}
    (lhs.ctrl_qubits == rhs.ctrl_qubits) && (lhs.block == rhs.block) && (lhs.addr == rhs.addr)
end

###################
# Primitive Blocks
###################

==(lhs::PhiGate, rhs::PhiGate) = lhs.theta == rhs.theta

function hash(gate::PhiGate, h::UInt)
    hash(hash(gate.theta, object_id(gate)), h)
end

==(lhs::RotationGate, rhs::RotationGate) = false
==(lhs::RotationGate{GT}, rhs::RotationGate{GT}) where GT = lhs.theta == rhs.theta

function hash(gate::RotationGate, h::UInt)
    hash(hash(gate.theta, object_id(gate)), h)
end

==(lhs::Swap, rhs::Swap) = (lhs.addr1 == rhs.addr1) && (lhs.addr2 == rhs.addr2)
