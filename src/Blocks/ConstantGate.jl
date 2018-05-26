"""
    ConstGate{N, GT, T} <: PrimitiveBlock{N, T}

`N` qubits gate whose matrix form is a constant.
"""
struct ConstGate{N, GT <: Val, T} <: PrimitiveBlock{N, T}
end

ConstGate(::Type{T}, ::Type{GT}) where {T, GT} = ConstGate{nqubits(GT), GT, T}()
ConstGate(::Type{T}, s::Symbol) where T = ConstGate(T, Val{s})

# NOTE: we bind some type related constants here to avoid multiple allocation

for NAME in [:X, :Y, :Z, :H]

    GT = Val{NAME}

    @eval begin
        nqubits(::Type{$GT}) = 1

        mat(gate::ConstGate{1, $GT, T}) where T = Const.Sparse.$NAME(T)
        full(gate::ConstGate{1, $GT, T}) where T = Const.Dense.$NAME(T)
        sparse(gate::ConstGate{1, $GT, T}) where T = Const.Sparse.$NAME(T)
        # traits
        isreflexive(gate::ConstGate{1, $GT, T}) where T = true
        ishermitian(gate::ConstGate{1, $GT, T}) where T = true

        # Pretty Printing
        function show(io::IO, block::ConstGate{1, $GT, T}) where T
            print(io, $(NAME), "{$T}")
        end
    end
end
