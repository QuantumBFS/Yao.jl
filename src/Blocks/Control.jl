mutable struct ControlBlock{BlockType, N, T} <: CompositeBlock{N, T}
    ctrl_qubits::Vector{Int}
    block::BlockType
    addr::Int

    # TODO: input a control block, we need to expand this control block to its upper parent block
    # function ControlBlock{N}(ctrl_qubits::Vector{Int}, ctrl::ControlBlock, addr::Int) where {N, K, T}
    # end

    function ControlBlock{BT, N, T}(ctrl_qubits::Vector{Int}, block::BT, addr::Int) where {BT, N, T}
        new{BT, N, T}(ctrl_qubits, block, addr)
    end

    function ControlBlock{N}(ctrl_qubits::Vector{Int}, block::BT, addr::Int) where {N, K, T, BT <: MatrixBlock{K, T}}
        # NOTE: control qubits use sign to characterize
        # inverse control qubits
        # we sort it from lowest addr to highest first
        # this will help we have an deterministic behaviour
        # TODO: remove repeated, add error
        ordered_control = sort(ctrl_qubits, by=x->abs(x))
        new{BT, N, T}(ordered_control, block, addr)
    end
end

function ControlBlock(ctrl_qubits::Vector{Int}, block, addr::Int)
    N = max(maximum(abs.(ctrl_qubits)), addr)
    ControlBlock{N}(ctrl_qubits, block, addr)
end

function copy(ctrl::ControlBlock{BT, N, T}) where {BT, N, T}
    ControlBlock{BT, N, T}(copy(ctrl.ctrl_qubits), copy(ctrl.block), copy(ctrl.addr))
end

function mat(ctrl::ControlBlock{BT, N, T}) where {BT, N, T}
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
        U = kron(U, speye(T, 1 << nblank))
    end

    # check blank lines in the end
    highest_addr = max(maximum(abs.(ctrl_addrs)), ctrl.addr)
    if highest_addr != N # highest addr is not the last
        nblank = N - highest_addr
        U = kron(speye(T, 1 << nblank), U)
    end
    U
end

function _single_inverse_control_gate_sparse(control::Int, U, addr, nqubit)
    @assert control != addr "cannot control itself"

    T = eltype(U)
    if control < addr
        op = A_kron_B(
            Const.Sparse.P1(T), control, 1,
            speye(U), addr
        )
        op += A_kron_B(
            Const.Sparse.P0(T), control, 1,
            U, addr
        )
    else
        op = A_kron_B(
            speye(U), addr, nqubit,
            Const.Sparse.P1(T), control
        )
        op += A_kron_B(
            U, addr, nqubit,
            Const.Sparse.P0(T), control
        )
    end
    op
end

function _single_control_gate_sparse(control::Int, U, addr, nqubit)
    @assert control != addr "cannot control itself"

    T = eltype(U)
    if control < addr
        op = A_kron_B(
            Const.Sparse.P0(T), control, 1,
            speye(U), addr
        )
        op += A_kron_B(
            Const.Sparse.P1(T), control, 1,
            U, addr
        )
    else
        op = A_kron_B(
            speye(U), addr, nqubit,
            Const.Sparse.P0(T), control
        )
        op += A_kron_B(
            U, addr, nqubit,
            Const.Sparse.P1(T), control
        )
    end
    op
end

# kronecker A and B relatively on position ia, ib
# A has size 2^na x 2^na
function A_kron_B(A, ia, na, B, ib)
    T = eltype(A)

    out = A
    if ia + na < ib
        blank_size = ib - ia - na
        out = kron(speye(T, 1 << blank_size), out)
    end
    kron(B, out)
end

struct ControlQuBit
    addr::Int
end

# Required Methods as Composite Block
function getindex(c::ControlBlock{BT, N}, index) where {BT, N}
    0 < index <= N || throw(BoundsError(c, index))

    if index == c.addr
        return c.block
    elseif index in c.ctrl_qubits
        return ControlQuBit(index)
    end

    throw(KeyError(index))
end

function setindex!(c::ControlBlock{BT, N}, val::MatrixBlock, index) where {BT, N}
    0 < index <= N || throw(BoundsError(c, index))

    if index == c.addr
        c.block = val
    else
        throw(KeyError(index))
    end
    c
end

start(c::ControlBlock) = 1
next(c::ControlBlock, st) = c.block, st + 1
done(c::ControlBlock, st) = st == 2
length(c::ControlBlock) = 1
eachindex(c::ControlBlock) = c.addr
blocks(c::ControlBlock) = [c.block]

# apply & dispatch
# TODO: overload this with direct apply method
# function apply!(reg::Register, ctrl::ControlBlock)
# end

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
