export GeneralMatrixGate

mutable struct GeneralMatrixGate{M, N, T, MT<:AbstractMatrix{T}} <: PrimitiveBlock{N, T}
    matrix :: MT
    function GeneralMatrixGate{M, N, T, MT}(matrix::MT) where {M, N, T, MT<:AbstractMatrix{T}}
        (1<<M == size(matrix, 1) && 1<<N == size(matrix, 2)) || throw(DimensionMismatch("Dimension of input matrix shape error."))
        new{M, N, T, MT}(matrix)
    end
end
GeneralMatrixGate(matrix::MT) where {T, MT<:AbstractMatrix{T}} = GeneralMatrixGate{log2i(size(matrix, 1)), log2i(size(matrix, 2)), T, MT}(matrix)

==(A::GeneralMatrixGate, B::GeneralMatrixGate) = A.matrix == B.matrix
copy(r::GeneralMatrixGate) = GeneralMatrixGate(copy(r.matrix))

mat(r::GeneralMatrixGate) = r.matrix

function print_block(io::IO, g::GeneralMatrixGate{M, N, T, MT}) where {M,N,T, MT}
    print("GeneralMatrixGate(2^$M × 2^$N; $MT)")
end
