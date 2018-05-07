struct ControlBlock{BlockType, N, T} <: CompositeBlock{N, T}
    control::Int

    block::BlockType
    pos::Int
end

function ControlBlock(total_num::Int, cbit::Int, block::BT, pos::Int) where {K, T, BT <: PureBlock{K, T}}
<<<<<<< HEAD
    new{BT, total_num, T}(qubits, block, pos)
=======
    new{BT, total_num, T}(cbit, block, pos)
>>>>>>> f9c6f28b9f3699452af8c9aebd9a1b68370496a5
end

function ControlBlock(cbit::Int, block::PureBlock{K, T}, pos::Int) where {K, T}
    total = max(pos + K - 1, cbit)
    ControlBlock{typeof(block), total, T}(cbit, block, pos)
end

function ControlBlock(cbit::Int, block::ControlBlock{BT, N, T}, pos::Int) where {BT, N, T}

    total = 0
    if cbit < pos
        total = pos + N - 1
    elseif pos + N - 1 < cbit
        total = cbit
    else
        total = N
    end

    ControlBlock{typeof(block), total, T}(cbit, block, pos)
end


for (NAME, MAT) in [
    ("P0", [1 0;0 0]),
    ("P1", [0 0;0 1]),
]

    for (TYPE_NAME, DTYPE) in [
        ("ComplexF16", Compat.ComplexF16),
        ("ComplexF32", Compat.ComplexF32),
        ("ComplexF64", Compat.ComplexF64),
    ]

        DENSE_NAME = Symbol(join(["CONST", NAME], "_"))
        DENSE_CONST = Symbol(join([DENSE_NAME, TYPE_NAME], "_"))

        SPARSE_NAME = Symbol(join(["CONST", "SPARSE", NAME], "_"))
        SPARSE_CONST = Symbol(join([SPARSE_NAME, TYPE_NAME], "_"))

        @eval begin
            const $(DENSE_CONST) = Array{$DTYPE, 2}($MAT)
            const $(SPARSE_CONST) = sparse(Array{$DTYPE, 2}($MAT))

            $(DENSE_NAME)(::Type{$DTYPE}) = $(DENSE_CONST)
            $(SPARSE_NAME)(::Type{$DTYPE}) = $(SPARSE_CONST)
        end
    end

end

function _kron_p_with_block(N, addr_p, p, addr_b, block::PureBlock{K, T}) where {K, T}
    local out
    
    if addr_p < addr_b
        out = speye(T, 1 << addr_p - 1)
        out = kron(out, p)
        out = kron(out, speye(T, 1 << (addr_b - addr_p - 1)))
        out = kron(out, sparse(block))
        out = kron(out, speye(T, 1 << (N - addr_b - K + 1)))
    else
    end
end

# - 1
# - 2 |
# - 3 |
# - 4
# - 5 |
# - 6 |
# - 7
# - 8

# kron 2^Jx2^J A with 2^K x 2^K B on given position ia, ib, ia < ib
function _kron_matAB(T, N, A, ia, J, B, ib, K)
    out = speye(T, 1 << ia - 1)
    out = kron(out, A)
    out = kron(out, speye(T, 1 << (ib - (ia + J)) ))
    out = kron(out, B)
    out = kron(out, speye(T, 1 << (N - (ib + K - 1)) ))
end

# TODO: polish this
function sparse(ctrl::ControlBlock{BT, N, T}) where {BT, N, T}

    local mat

    if ctrl.control < ctrl.pos
        mat = _kron_matAB(
            T, N,
            CONST_SPARSE_P0(T), ctrl.control, 1,
            sparse(ctrl.block), ctrl.pos, N - 1,
        )
        mat += _kron_matAB(
            T, N,
            CONST_SPARSE_P1(T), ctrl.control, 1,
            sparse(ctrl.block), ctrl.pos, N - 1,
        )
    else
        mat = _kron_matAB(
            T, N,
            sparse(ctrl.block), ctrl.pos, N - 1,
            CONST_SPARSE_P0(T), ctrl.control, 1,
        )
        mat += _kron_matAB(
            T, N,
            sparse(ctrl.block), ctrl.pos, N - 1,
            CONST_SPARSE_P1(T), ctrl.control, 1,
        )
    end

    return mat
end

full(ctrl::ControlBlock) = full(sparse(ctrl))

function apply!(reg::Register, ctrl::ControlBlock)
    reg.state .= full(ctrl) * reg
    reg
end

function dispatch!(ctrl::ControlBlock, params...)
    dispatch!(ctrl.block, params...)
end

# TODO: use this type to optimize performance for multiple control qubits
struct MultiControlBlock{M, BlockType, N, T} <: CompositeBlock{N, T}
    control_qubits::NTuple{M, Int}

    block::BlockType
    pos::Int

    function MultiControlBlock(control_qubits::NTuple{M, Int}, block::BT, pos::Int) where {M, K, T, BT <: PureBlock{K, T}}
        warn("MultiControlBlock is not implemented")
        new{M, BT, M+K, T}(control_qubits, block, pos)
    end
end


# factory method
export control

control(cbit, block::PureBlock, pos) = ControlBlock(cbit, block, pos)

function show(io::IO, ctrl::ControlBlock)
    println(io, "control (", ctrl.control, "):")
    print(io, "    ", ctrl.pos, ": ", ctrl.block)
end

