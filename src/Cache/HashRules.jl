import Base: hash, ==

###################
# Composite Blocks
###################

function hash(c::ChainBlock, h::UInt)
    hashkey = hash(object_id(c), h)
    for each in c.blocks
        hashkey = hash(each, hashkey)
    end
    hashkey
end

==(lhs::ChainBlock, rhs::ChainBlock) = false
==(lhs::ChainBlock{N, T}, rhs::ChainBlock{N, T}) where {N, T} = all(lhs.blocks .== rhs.blocks)


function hash(block::KronBlock{N, T}, h::UInt) where {N, T}
    hashkey = hash(object_id(block), h)
    for each in values(block)
        hashkey = hash(each, hashkey)
    end
    hashkey
end

==(lhs::KronBlock, rhs::KronBlock) = false
==(lhs::KronBlock{N, T}, rhs::KronBlock{N, T}) where {N, T} = (lhs.kvstore == rhs.kvstore)


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
