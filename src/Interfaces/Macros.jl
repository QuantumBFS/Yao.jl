export @const_gate

macro const_gate(expr)
    @capture(expr, NAME_ = EXPR_)
    CONST_NAME = Symbol(join([NAME, "CONST"], "_"))
    ESC_CONST_NAME = esc(CONST_NAME)
    GateType = Val{NAME}

    nqubits_ex = :(nqubits(::Type{$GateType}) = log2i(size($CONST_NAME, 1)))
    mat_ex = :(mat(gate::ConstGate{N, $GateType, eltype($CONST_NAME)}) = $CONST_NAME)

    quote
        import QuCircuit: nqubits, mat, isreflexive, ishermitian, ConstGate, show, KronBlock, PrimitiveBlock
        const $CONST_NAME = $EXPR

        N = log2i(size($CONST_NAME, 1))

        struct $NAME{T} <: PrimitiveBlock{N, T}
        end

        $(esc(:nqubits))(::Type{$GateType}) = log2i(size($CONST_NAME, 1))
        $(esc(:mat))(gate::ConstGate{N, $(GateType), eltype($CONST_NAME)}) = $CONST_NAME
        # TODO: refactor this to a type trait
        $(esc(:isreflexive))(gate::ConstGate{N, $GateType, eltype($CONST_NAME)}) = check_reflexive($CONST_NAME)
        $(esc(:ishermitian))(gate::ConstGate{N, $GateType, eltype($CONST_NAME)}) = check_hermitian($CONST_NAME)

        $(esc(NAME))() = gate($GateType)
        $(esc(NAME))(r) = (gate($GateType), r)
        $(esc(NAME))(n::Int, addr::Int) = KronBlock{n}(1=>gate($GateType))
        $(esc(NAME))(n::Int, r) = KronBlock{n}(collect(r), collect(gate($GateType) for i in r))

        function $(esc(:show))(io::IO, gate::ConstGate{N, $GateType, eltype($CONST_NAME)})
            print(io, $(string(NAME)))
        end
    end
end


check_hermitian(op) = op' ≈ op

function check_reflexive(op)
    op * op ≈ speye(size(op, 1))
end


function declare_const_gate(typename, name)
    typed_name = join()
end
