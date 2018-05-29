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

function ==(lhs::ChainBlock{N, T}, rhs::ChainBlock{N, T}) where {N, T}
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

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

function ==(lhs::ControlBlock{BT, N, T}, rhs::ControlBlock{BT, N, T}) where {BT, N, T}
    (lhs.ctrl_qubits == rhs.ctrl_qubits) && (lhs.block == rhs.block) && (lhs.addr == rhs.addr)
end

==(lhs::Roller{N, M, T, BT}, rhs::Roller{N, M, T, BT}) where {N, M, T, BT} = lhs.blocks == rhs.blocks

function hash(R::Roller, h::UInt)
    hashkey = hash(object_id(R), h)
    for each in R.blocks
        hashkey = hash(each, hashkey)
    end
    hashkey
end

###################
# Primitive Blocks
###################

# ==(lhs::Swap, rhs::Swap) = (lhs.addr1 == rhs.addr1) && (lhs.addr2 == rhs.addr2)
