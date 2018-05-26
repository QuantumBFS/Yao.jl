"""
    Gate{N, GT, T} <: PrimitiveBlock{N, T}

`N` qubits gate whose matrix form is a constant.
"""
struct Gate{N, GT <: GateType, T} <: PrimitiveBlock{N, T}
end

Gate(::Type{T}, ::Type{GT}) where {T, GT} = Gate{nqubits(GT), GT, T}()
Gate(::Type{T}, s::Symbol) where T = Gate(T, GateType{s})

# NOTE: we bind some type related constants here to avoid multiple allocation

for NAME in [:X, :Y, :Z, :H]

    GT = GateType{NAME}

    @eval begin
        nqubits(::Type{$GT}) = 1

        full(gate::Gate{1, $GT, T}) where T = Const.Dense.$NAME(T)
        sparse(gate::Gate{1, $GT, T}) where T = Const.Sparse.$NAME(T)
        # traits
        isreflexive(gate::Gate{1, $GT, T}) where T = true
        ishermitian(gate::Gate{1, $GT, T}) where T = true

        # Pretty Printing
        function show(io::IO, block::Gate{1, $GT, T}) where T
            print(io, $(NAME), "{$T}")
        end
    end
end
