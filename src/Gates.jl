import Base: size, sparse, full

export apply!, update!

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
    apply(gate, reg, pos) -> reg

apply the `gate` to qubits start from `pos` on register `reg`,
by default it will use kronecker product to build an operator
in the whole scope and apply it to the state.

```math
I^{pos-1}\\otimes OP\\otimes I^{N-M-pos+1}
```
"""
function apply!(gate::AbstractGate{M}, reg::AbstractRegister{T, N}, pos) where {T, M, N}
    op = kron(kron(speye(2^(N-M-pos+1)), sparse(gate)), speye(2^(pos-1)))
    reg.state = op * reg.state
    return reg
end

"""
    apply(gate, reg) -> reg

apply the `gate` to qubits from its begining on register `reg`, default is an identity
"""
apply!(gate::AbstractGate, reg) = apply!(gate, reg, 1)

"""
    update!(gate, paras) -> gate

update parameters inside a parameterized gate,
this method will have side effect on gates.
"""
update!(gate::AbstractGate, params) = gate
