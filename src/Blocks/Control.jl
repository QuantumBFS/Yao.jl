export ControlBlock

tuplesort(tp; by::Function=x->x) = (sort([tp...], by=by)...)

"""
    ControlBlock{BT, N, C, B, T}

BT: controlled block type,
N: number of qubits,
C: number of control bits,
T: type of matrix.
"""
mutable struct ControlBlock{BT, N, C, T} <: CompositeBlock{N, T}
    ctrl_qubits::NTuple{C, Int}
    projectors::NTuple{C, Matrix{T}}
    block::BT
    addr::Int

    # TODO: input a control block, we need to expand this control block to its upper parent block
    # function ControlBlock{N}(ctrl_qubits::Vector{Int}, ctrl::ControlBlock, addr::Int) where {N, K, T}
    # end

    function ControlBlock{N, T}(ctrl_qubits::NTuple{C, Int}, projectors::NTuple{C, Matrix{T}}, block::BT, addr::Int) where {BT, N, C, T}
        new{BT, N, C, T}(ctrl_qubits |> tuplesort, projectors, block, addr)
    end

    function ControlBlock{N}(ctrl_qubits::NTuple{C}, projectors::NTuple{C, Matrix{T}}, block::BT, addr::Int) where {N, C, B, T, BT <: MatrixBlock{B, T}}
        new{BT, N, C, T}(ctrl_qubits |> tuplesort, projectors, block, addr)
    end
end

function ControlBlock{N}(ctrl_qubits::NTuple{C}, target::Pair{Int, BT}) where {N, K, C, T, BT <: MatrixBlock{K, T}}
    ControlBlock{N}(ctrl_qubits, target.second, target.first)
end

function ControlBlock(ctrl_qubits::NTuple, block, addr::Int)
    N = max(maximum(abs.(ctrl_qubits)), addr)
    ControlBlock{N}(ctrl_qubits, block, addr)
end

function copy(ctrl::ControlBlock{BT, N, C, T}) where {BT, N, C, T}
    ControlBlock{BT, N, C, T}(copy(ctrl.ctrl_qubits), ctrl.block, copy(ctrl.addr))
end

general_controlled_gates(num_bit::Int, projectors::Vector{Tp}, cbits::Vector{Int}, gates::Vector{Tg}, locs::Vector{Int}) where {Tg<:AbstractMatrix, Tp<:AbstractMatrix} = IMatrix(1<<num_bit) - superkron(num_bit, projectors, cbits) + superkron(num_bit, vcat(projectors, gates), vcat(cbits, locs))

function mat(ctrl::ControlBlock{BT, N, C, T}) where {BT, N, C, T}
    # NOTE: we sort the addr of control qubits by its relative addr to
    # the block under control, this is useful when calculate its
    # matrix form.
    ctrl_addrs = sort(ctrl.ctrl_qubits, by=x->abs(abs(x)-ctrl.addr))

    # start of the iteration
    U = mat(ctrl.block)
    addr = ctrl.addr
    U_nqubit = nqubits(ctrl.block)
    for each_ctrl in ctrl_addrs
        if each_ctrl > 0
            U = _single_control_gate_sparse(abs(each_ctrl), U, addr, U_nqubit)
        else
            U = _single_inverse_control_gate_sparse(abs(each_ctrl), U, addr, U_nqubit)
        end

        head = addr # inner block head
        tail = addr + U_nqubit - 1 # inner block tail
        inc = min(abs(head - abs(each_ctrl)), abs(tail - abs(each_ctrl)))
        U_nqubit = U_nqubit + inc
        addr = min(abs(each_ctrl), addr)
    end

    # check blank lines at the beginning
    lowest_addr = min(minimum(abs.(ctrl_addrs)), ctrl.addr)
    if lowest_addr != 1 # lowest addr is not from the first
        nblank = lowest_addr - 1
        U = kron(U, IMatrix{1 << nblank, T}())
    end

    # check blank lines in the end
    highest_addr = max(maximum(abs.(ctrl_addrs)), ctrl.addr)
    if highest_addr != N # highest addr is not the last
        nblank = N - highest_addr
        U = kron(IMatrix{1 << nblank, T}(), U)
    end
    U
end

blocks(c::ControlBlock) = [c.block]

#################
# Dispatch Rules
#################

# NOTE: ControlBlock will forward parameters directly without loop
function dispatch!(f::Function, ctrl::ControlBlock, params::Vector)
    dispatch!(f, ctrl.block, params)
end

function dispatch!(f::Function, ctrl::ControlBlock, params...)
    dispatch!(f, ctrl.block, params...)
end

function hash(ctrl::ControlBlock, h::UInt)
    hashkey = hash(objectid(ctrl), h)
    for each in ctrl.ctrl_qubits
        hashkey = hash(each, hashkey)
    end

    hashkey = hash(ctrl.block, hashkey)
    hashkey = hash(ctrl.addr, hashkey)
    hashkey
end

function ==(lhs::ControlBlock{BT, N, C, T}, rhs::ControlBlock{BT, N, C, T}) where {BT, N, C, T}
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
