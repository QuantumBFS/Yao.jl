export GeneralMatrixGate

mutable struct GeneralMatrixGate{M, N, T} <: PrimitiveBlock{N, T}
    matrix :: AbstractMatrix{T}
    function GeneralMatrixGate{M, N, T}(matrix::AbstractMatrix{T}) where {M, N, T}
        (1<<M == size(matrix, 1) && 1<<N == size(matrix, 2)) || throw(DimensionMismatch("Dimension of input matrix shape error."))
        new{M, N, T}(matrix)
    end
end
GeneralMatrixGate(matrix::AbstractMatrix{T}) where T = GeneralMatrixGate{log2i(size(matrix, 1)), log2i(size(matrix, 2)), T}(matrix)

==(A::GeneralMatrixGate, B::GeneralMatrixGate) = A.matrix == B.matrix
copy(r::GeneralMatrixGate) = GeneralMatrixGate(copy(r.matrix))

mat(r::GeneralMatrixGate) = r.matrix

function print_block(io::IO, g::GeneralMatrixGate{M, N, T}) where {M,N,T}
    print("GeneralMatrixGate(2^$M × 2^$N)")
end
