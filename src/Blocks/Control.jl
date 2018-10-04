export ControlBlock

"""
    ControlBlock{BT, N, C, B, T} <: NonParametricContainer{N, T}

N: number of qubits,
BT: controlled block type,
C: number of control bits,
T: type of matrix.
"""
mutable struct ControlBlock{N, BT<:AbstractBlock, C, M, T} <: NonParametricContainer{N, T}
    ctrl_qubits::NTuple{C, Int}
    vals::NTuple{C, Int}
    block::BT
    addrs::NTuple{M, Int}
    function ControlBlock{N, BT, C, M, T}(ctrl_qubits, vals, block, addrs) where {N, C, M, T, BT<:AbstractBlock}
        _assert_addr_safe(N, [ctrl_qubits..., addrs...])
        new{N, BT, C, M, T}(ctrl_qubits, vals, block, addrs)
    end
end

function ControlBlock{N}(ctrl_qubits::NTuple{C}, vals::NTuple{C}, block::BT, addrs::NTuple{M}) where {BT<:AbstractBlock, N, C, M}
    ControlBlock{N, BT, C, M, Bool}(ctrl_qubits, vals, block, addrs)
end

function ControlBlock{N}(ctrl_qubits::NTuple{C}, vals::NTuple{C}, block::BT, addrs::NTuple{K}) where {N, M, C, K, T, BT<:MatrixBlock{M, T}}
    M == K || throw(DimensionMismatch("block position not maching its size!"))
    ControlBlock{N, BT, C, M, T}(ctrl_qubits, vals, block, addrs)
end

ControlBlock{N}(ctrl_qubits::NTuple{C}, block::AbstractBlock, addrs::NTuple) where {N, C} =
    ControlBlock{N}(ctrl_qubits, (ones(Int, C)..., ), block, addrs)

function copy(ctrl::ControlBlock{N, BT, C, M, T}) where {BT, N, C, M, T}
    ControlBlock{N, BT, C, M, T}(ctrl.ctrl_qubits, ctrl.vals, ctrl.block, ctrl.addrs)
end

projector(val) = val==0 ? mat(P0) : mat(P1)

#mat(c::ControlBlock{N, BT, C, 1}) where {N, BT, C} = general_controlled_gates(N, [(c.vals .|> projector)...], [c.ctrl_qubits...], [mat(c.block)], [c.addrs...])
mat(c::ControlBlock{N, BT, C}) where {N, BT, C} = cunmat(N, c.ctrl_qubits, c.vals, mat(c.block), c.addrs)
apply!(reg::DefaultRegister, c::ControlBlock) = (cunapply!(reg.state |> matvec, c.ctrl_qubits, c.vals, mat(c.block), c.addrs); reg)
adjoint(blk::ControlBlock{N}) where N = ControlBlock{N}(blk.ctrl_qubits, blk.vals, adjoint(blk.block), blk.addrs)

addrs(c::ControlBlock) = c.addrs
usedbits(c::ControlBlock) = [c.ctrl_qubits..., c.addrs[usedbits(c.block)]...]
chblock(pb::ControlBlock{N}, blk::AbstractBlock) where {N} = ControlBlock{N}(pb.ctrl_qubits, pb.vals, blk, pb.addrs)

#################
# Dispatch Rules
#################

# NOTE: ControlBlock will forward parameters directly without loop
cache_key(ctrl::ControlBlock) = cache_key(ctrl.block)

function hash(ctrl::ControlBlock, h::UInt)
    hashkey = hash(objectid(ctrl), h)
    for each in ctrl.ctrl_qubits
        hashkey = hash(each, hashkey)
    end

    hashkey = hash(ctrl.block, hashkey)
    hashkey = hash(ctrl.addrs, hashkey)
    hashkey
end

function ==(lhs::ControlBlock{N, BT, C, M, T}, rhs::ControlBlock{N, BT, C, M, T}) where {BT, N, C, M, T}
    (lhs.ctrl_qubits == rhs.ctrl_qubits) && (lhs.block == rhs.block) && (lhs.addrs == rhs.addrs)
end

function print_block(io::IO, x::ControlBlock)
    printstyled(io, "control("; bold=true, color=color(ControlBlock))

    for i in eachindex(x.ctrl_qubits)
        printstyled(io, x.ctrl_qubits[i]; bold=true, color=color(ControlBlock))

        if i != lastindex(x.ctrl_qubits)
            printstyled(io, ", "; bold=true, color=color(ControlBlock))
        end
    end
    printstyled(io, ")"; bold=true, color=color(ControlBlock))
end
