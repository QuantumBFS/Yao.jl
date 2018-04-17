import Base: size, sparse, full

export apply, update!

"""
    AbstractGate{N}

Abstract type for quantum gates.
"""
abstract type AbstractGate{N} end

"""
    size(gate::AbstractGate)

get the size of the given gate (number of qubits)
"""
size(gate::AbstractGate{N}) where N = N

"""
    sparse(gate::AbstractGate) -> SparseMatrixCSC

get the sparse matrix form of the given gate, default is an identity
"""
sparse(::Type{T}, gate::AbstractGate{N}) where {T, N} = speye(T, N)
sparse(gate::AbstractGate) = sparse(Complex128, gate)

"""
    full(gate::AbstractGate) -> DenseMatrix

get the dense matrix form of the given gate, default is an identity
"""
full(::Type{T}, gate::AbstractGate{N}) where {T, N} = eye(T, N)
full(gate::AbstractGate) = full(Complex128, gate)

"""
    apply(gate, state, pos) -> state

apply the `gate` to qubits start from `pos` on `state`, default is an identity
"""
apply(gate::AbstractGate, state, pos) = state

"""
    apply(gate, state) -> state

apply the `gate` to qubits from its begining on `state`, default is an identity
"""
apply(gate::AbstractGate, state) = apply(gate, state, 1)

"""
    update!(gate, paras) -> gate

update parameters inside a parameterized gate,
this method will have side effect on gates.
"""
update!(gate::AbstractGate, params) = gate
