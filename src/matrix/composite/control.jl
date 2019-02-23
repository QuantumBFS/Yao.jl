export ControlBlock

mutable struct ControlBlock{N, BT<:AbstractBlock, C, M, T} <: AbstractContainer{N, T}
    ctrl_qubits::NTuple{C, Int}
    vals::NTuple{C, Int}
    block::BT
    addrs::NTuple{M, Int}
    function ControlBlock{N, BT, C, M, T}(ctrl_qubits, vals, block, addrs) where {N, C, M, T, BT<:AbstractBlock}
        @assert_addrs N (ctrl_qubits..., addrs...)
        new{N, BT, C, M, T}(ctrl_qubits, vals, block, addrs)
    end
end

function ControlBlock{N}(ctrl_qubits::NTuple{C}, vals::NTuple{C}, block::BT, addrs::NTuple{M}) where {BT<:AbstractBlock, N, C, M}
    return ControlBlock{N, BT, C, M, Bool}(ctrl_qubits, vals, block, addrs)
end

function ControlBlock{N}(ctrl_qubits::NTuple{C}, vals::NTuple{C}, block::BT, addrs::NTuple{K}) where {N, M, C, K, T, BT<:MatrixBlock{M, T}}
    M == K || throw(DimensionMismatch("block position not maching its size!"))
    return ControlBlock{N, BT, C, M, T}(ctrl_qubits, vals, block, addrs)
end

ControlBlock{N}(ctrl_qubits::NTuple{C}, block::AbstractBlock, addrs::NTuple) where {N, C} =
    ControlBlock{N}(ctrl_qubits, (ones(Int, C)..., ), block, addrs)

mat(c::ControlBlock{N, BT, C}) where {N, BT, C} = cunmat(N, c.ctrl_qubits, c.vals, mat(c.block), c.addrs)
apply!(r::ArrayReg, c::ControlBlock) =
    instruct!(matvec(r.state), mat(c.block), c.addrs, c.ctrl_qubits, c.vals)

PreserveStyle(::ControlBlock) = PreserveAll()
iscommute(x::ControlBlock{N}, y::ControlBlock{N}) where N = x.addrs == y.addrs && x.ctrl_qubits == y.ctrl_qubits ? iscommute(x.block, y.block) : _default_iscommute(x, y)

occupied_locations(c::ControlBlock) = (c.ctrl_qubits..., map(x->c.addrs[x], occupied_locations(c.block))...)
chblock(pb::ControlBlock{N}, blk::AbstractBlock) where {N} = ControlBlock{N}(pb.ctrl_qubits, pb.vals, blk, pb.addrs)

# NOTE: ControlBlock will forward parameters directly without loop
cache_key(ctrl::ControlBlock) = cache_key(ctrl.block)

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

function Base:(==)(lhs::ControlBlock{N, BT, C, M, T}, rhs::ControlBlock{N, BT, C, M, T}) where {BT, N, C, M, T}
    return (lhs.ctrl_qubits == rhs.ctrl_qubits) && (lhs.block == rhs.block) && (lhs.addrs == rhs.addrs)
end

Base.adjoint(blk::ControlBlock{N}) where N = ControlBlock{N}(blk.ctrl_qubits, blk.vals, adjoint(blk.block), blk.addrs)

# NOTE: we only copy one hierachy (shallow copy) for each block
function Base.copy(ctrl::ControlBlock{N, BT, C, M, T}) where {BT, N, C, M, T}
    return ControlBlock{N, BT, C, M, T}(ctrl.ctrl_qubits, ctrl.vals, ctrl.block, ctrl.addrs)
end
