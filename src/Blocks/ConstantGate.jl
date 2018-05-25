"""
    Gate{N, GT, T} <: PrimitiveBlock{N, T}

`N` qubits gate whose matrix form is a constant.
"""
struct Gate{N, GT <: GateType, T} <: PrimitiveBlock{N, T}
end

Gate(::Type{T}, s::Symbol) where T = Gate(T, GateType{s})

# NOTE: we bind some type related constants here to avoid multiple allocation

for (GTYPE, NAME) in [
    (:X, "PAULI_X"),
    (:Y, "PAULI_Y"),
    (:Z, "PAULI_Z"),
    (:H, "HADMARD")
]

    DENSE_NAME = Symbol(join(["CONST", NAME], "_"))
    SPARSE_NAME = Symbol(join(["CONST", "SPARSE", NAME], "_"))
    GT = GateType{GTYPE}

    @eval begin
        Gate(::Type{T}, x::Type{$GT}) where T = Gate{1, $GT, T}()

        full(gate::Gate{1, $GT, T}) where T = $(DENSE_NAME)(T)
        sparse(gate::Gate{1, $GT, T}) where T = $(SPARSE_NAME)(T)
        # traits
        isreflexive(gate::Gate{1, $GT, T}) where T = true
        ishermitian(gate::Gate{1, $GT, T}) where T = true
    end
end

# Pretty Printing

for NAME in [
    :X, :Y, :Z, :H,
]

    GT = GateType{NAME}

@eval begin
    function show(io::IO, block::Gate{1, $GT, T}) where T
        print(io, $(NAME), "{$T}")
    end
end

end