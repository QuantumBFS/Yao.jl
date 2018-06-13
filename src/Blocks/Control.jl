export ControlBlock

"""
    ControlBlock{BT, N, C, B, T} <: CompositeBlock{N, T}

N: number of qubits,
BT: controlled block type,
C: number of control bits,
T: type of matrix.
"""
mutable struct ControlBlock{N, BT<:AbstractBlock, C, T} <: CompositeBlock{N, T}
    ctrl_qubits::NTuple{C, Int}
    vals::NTuple{C, Int}
    block::BT
    addr::Int
    function ControlBlock{N, BT, C, T}(ctrl_qubits, vals, block, addr) where {N, C, T, BT<:AbstractBlock}
        _assert_addr_safe(N, [[b:b for b in ctrl_qubits]; [addr:addr+nqubits(block)-1]])
        new{N, BT, C, T}(ctrl_qubits, vals, block, addr)
    end
end

function ControlBlock{N}(ctrl_qubits::NTuple{C, Int}, vals::NTuple{C, Int}, block::BT, addr::Int) where {BT<:AbstractBlock, N, C}
    ControlBlock{N, BT, C, Bool}(ctrl_qubits, vals, block, addr)
end

function ControlBlock{N}(ctrl_qubits::NTuple{C, Int}, vals::NTuple{C, Int}, block::BT, addr::Int) where {N, M, C, T, BT<:MatrixBlock{M, T}}
    ControlBlock{N, BT, C, T}(ctrl_qubits, vals, block, addr)
end

ControlBlock{N}(ctrl_qubits::NTuple{C, Int}, block::AbstractBlock, addr::Int) where {N, C} = ControlBlock{N}(ctrl_qubits, (ones(Int, C)...), block, addr)

function copy(ctrl::ControlBlock{N, BT, C, T}) where {BT, N, C, T}
    ControlBlock{N, BT, C, T}(ctrl.ctrl_qubits, ctrl.vals, ctrl.block, ctrl.addr)
end

projector(val) = val==0 ? mat(P0) : mat(P1)

general_controlled_gates(num_bit::Int, projectors::Vector{Tp}, cbits::Vector{Int}, gates::Vector{Tg}, locs::Vector{Int}) where {Tg<:AbstractMatrix, Tp<:AbstractMatrix} =
IMatrix(1<<num_bit) - hilbertkron(num_bit, projectors, cbits) + hilbertkron(num_bit, vcat(projectors, gates), vcat(cbits, locs))

general_c1_gates(num_bit::Int, projector::Tp, cbit::Int, gates::Vector{Tg}, locs::Vector{Int}) where {Tg<:AbstractMatrix, Tp<:AbstractMatrix} =
hilbertkron(num_bit, [mat(I2) - projector], [cbit]) + hilbertkron(num_bit, vcat([projector], gates), vcat([cbit], locs))

mat(c::ControlBlock{N}) where N = general_controlled_gates(N, [(c.vals .|> projector)...], [c.ctrl_qubits...], [mat(c.block)], [c.addr])
mat(c::ControlBlock{N, BT, 1}) where {N, BT} = general_c1_gates(N, c.vals[1] |> projector, c.ctrl_qubits[1], [mat(c.block)], [c.addr])

blocks(c::ControlBlock) = [c.block]
addrs(c::ControlBlock) = [c.addr]
usedbits(c::ControlBlock) = [c.ctrl_qubits..., ((c.addr-1).+usedbits(c.block))...]

#################
# Dispatch Rules
#################

# NOTE: ControlBlock will forward parameters directly without loop
dispatch!(ctrl::ControlBlock, params...) = dispatch!(ctrl.block, params...)
dispatch!(f::Function, ctrl::ControlBlock, params...) = dispatch!(f, ctrl.block, params...)
cache_key(ctrl::ControlBlock) = cache_key(ctrl.block)

function hash(ctrl::ControlBlock, h::UInt)
    hashkey = hash(objectid(ctrl), h)
    for each in ctrl.ctrl_qubits
        hashkey = hash(each, hashkey)
    end

    hashkey = hash(ctrl.block, hashkey)
    hashkey = hash(ctrl.addr, hashkey)
    hashkey
end

function ==(lhs::ControlBlock{N, BT, C, T}, rhs::ControlBlock{N, BT, C, T}) where {BT, N, C, T}
    (lhs.ctrl_qubits == rhs.ctrl_qubits) && (lhs.block == rhs.block) && (lhs.addr == rhs.addr)
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
