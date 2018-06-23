struct SSparseMatrixCSC{Tv,Ti<:Integer, NNZ, NP} <: AbstractSparseMatrix{Tv,Ti}
    m::Int                  # Number of rows
    n::Int                  # Number of columns
    colptr::SVector{NP,Ti}      # Column i is in colptr[i]:(colptr[i+1]-1)
    rowval::SVector{NNZ,Ti}      # Row values of nonzeros
    nzval::SVector{NNZ,Tv}       # Nonzero values

    function SSparseMatrixCSC{Tv,Ti, NNZ, NP}(m::Integer, n::Integer, colptr::SVector{NP, Ti}, rowval::SVector{NNZ,Ti},
                                    nzval::SVector{NNZ,Tv}) where {Tv,Ti<:Integer, NNZ, NP}
        m < 0 && throw(ArgumentError("number of rows (m) must be ≥ 0, got $m"))
        n < 0 && throw(ArgumentError("number of columns (n) must be ≥ 0, got $n"))
        new(Int(m), Int(n), colptr, rowval, nzval)
    end
end

function SSparseMatrixCSC(m::Integer, n::Integer, colptr::SVector, rowval::SVector, nzval::SVector)
    Tv = eltype(nzval)
    Ti = promote_type(eltype(colptr), eltype(rowval))
    SSparseMatrixCSC{Tv,Ti,length(nzval),n+1}(m, n, colptr, rowval, nzval)
end


struct SDiagonal{T, N} <: AbstractMatrix{T}
    diag::SVector{N, T}
end
SDiagonal(V::AbstractVector{T}) where T = SDiagonal{T, length(V)}(SVector{length{V}}(V))

######### statify ##########
"""
    statify(A::AbstractMatrix) -> AbastractMatrix

transform a matrix to a static form.
"""
function statify end

statify(A::AbstractMatrix) = SMatrix{size(A,1), size(A,2)}(A)
statify(A::AbstractVector) = SVector{length(A)}(A)
statify(A::Diagonal) = SDiagonal(SVector{size(A,1)}(A.diag))
statify(A::PermMatrix) = PermMatrix(SVector{size(A,1)}(A.perm), SVector{size(A, 1)}(A.vals))

function statify(A::SparseMatrixCSC)
    SSparseMatrixCSC(A.m, A.n, SVector{length(A.colptr)}(A.colptr), SVector{length(A.rowval)}(A.rowval), SVector{length(A.nzval)}(A.nzval))
end
