# basis ordering:
# n = 1: [1, -1] => [1', -1']
# n = 2: [1, 2, -1, -2] => [1', 2', -1', -2']; however, after kron, the basis is [1, -1, 2, -2] => [1', -1', 2', -2']
# n = 2: [1, 2, 3, -1, -2, -3] => [1', 2', 3', -1', -2', -3']; however, after kron, the basis is [1, -1, 2, -2, 3, -3] => [1', -1', 2', -2', 3', -3']
# So, we need to reorder the basis after kron.
function pauli_basis_transformer(::Type{T}, n::Int) where {T}
    PAULI_BASIS_TRANSFORM = sparse(T[1 0 0 1; 0 1 -im 0; 0 1 im 0; 1 0 0 -1])
    # TODO: verify the ordering
    return YaoBlocks.reorder(reduce(YaoBlocks.fastkron, [PAULI_BASIS_TRANSFORM for _=1:n]), [1:2:2n..., 2:2:2n...])
end

function to_pauli_basis(rho::DensityMatrix{2, T}) where {T}
    n = nqubits(rho)
    U = pauli_basis_transformer(T, n)
    return DensityMatrix{2}(reshape(U * vec(rho.state) ./ sqrt(2^n), 2^n, 2^n))
end

function to_pauli_basis(op::SuperOp{2, T}) where {T}
    n = nqubits(op)
    U = pauli_basis_transformer(T, n)
    return SuperOp{2}(U * op.superop * U' ./ 2^n)
end

# observables in pauli basis are similar to bra.
function to_pauli_basis_observable(mat::AbstractMatrix{T}) where {T}
    n = YaoBlocks.log2i(size(mat, 1))
    U = pauli_basis_transformer(T, n)
    return reshape(transpose(vec(transpose(mat))) * U' ./ sqrt(2^n), 2^n, 2^n)
end