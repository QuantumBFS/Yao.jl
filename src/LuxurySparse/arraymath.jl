import Base: conj, copy, real, ctranspose, imag
import Compat.LinearAlgebra: transpose, transpose!, ctranspose!

@static if VERSION >= v"0.7-"
    import LinearAlgebra: adjoint!, adjoint
end


# IMatrix
for func in (:conj, :real, :ctranspose, :transpose, :adjoint, :copy)
    @eval ($func)(M::IMatrix{N, T}) where {N, T} = IMatrix{N, T}()
end
for func in (:ctranspose!, :adjoint!, :transpose!)
    @eval ($func)(M::IMatrix) = M
end
imag(M::IMatrix{N, T}) where {N, T} = Diagonal(zeros(T,N))

# PermMatrix
for func in (:conj, :real, :imag)
    @eval ($func)(M::PermMatrix) = PermMatrix(M.perm, ($func)(M.vals))
end
copy(M::PermMatrix) = PermMatrix(copy(M.perm), copy(M.vals))

function transpose(M::PermMatrix)
    new_perm = fast_invperm(M.perm)
    return PermMatrix(new_perm, M.vals[new_perm])
end

adjoint(S::PermMatrix{<:Real}) = transpose(S)
adjoint(S::PermMatrix{<:Complex}) = conj(transpose(S))


# scalar
import Base: *, /, ==, +, -, ≈
*(A::IMatrix{N, T}, B::Number) where {N, T} = Diagonal(fill(promote_type(T, eltype(B))(B), N))
*(B::Number, A::IMatrix{N, T}) where {N, T} = Diagonal(fill(promote_type(T, eltype(B))(B), N))
/(A::IMatrix{N, T}, B::Number) where {N, T} = Diagonal(fill(promote_type(T, eltype(B))(1/B), N))

*(A::PermMatrix, B::Number) = PermMatrix(A.perm, A.vals*B)
*(B::Number, A::PermMatrix) = A*B
/(A::PermMatrix, B::Number) = PermMatrix(A.perm, A.vals/B)
#+(A::PermMatrix, B::PermMatrix) = PermMatrix(A.dv+B.dv, A.ev+B.ev)
#-(A::PermMatrix, B::PermMatrix) = PermMatrix(A.dv-B.dv, A.ev-B.ev)


const IDP = Union{Diagonal, PermMatrix, IMatrix}
for op in [:+, :-, :(==), :≈]

    @eval begin
        $op(A::IDP, B::SparseMatrixCSC) = $op(SparseMatrixCSC(A), B)
        $op(B::SparseMatrixCSC, A::IDP) = $op(B, SparseMatrixCSC(A))

        # intra-IDP
        $op(A::PermMatrix, B::IDP) = $op(SparseMatrixCSC(A), SparseMatrixCSC(B))
        $op(A::IDP, B::PermMatrix) = $op(SparseMatrixCSC(A), SparseMatrixCSC(B))
        $op(A::PermMatrix, B::PermMatrix) = $op(SparseMatrixCSC(A), SparseMatrixCSC(B))
    end

    # intra-ID
    if op in [:+, :-]
        @eval begin
            $op(d1::Diagonal, d2::IMatrix) = Diagonal($op(d1.diag, diag(d2)))
            $op(d1::IMatrix, d2::Diagonal) = Diagonal($op(diag(d1), d2.diag))
        end
    else
        @eval begin
            $op(d1::IMatrix, d2::Diagonal) = $op(diag(d1), d2.diag)
            $op(d1::Diagonal, d2::IMatrix) = $op(d1.diag, diag(d2))
            $op(d1::IMatrix{Na}, d2::IMatrix{Nb}) where {Na, Nb} = $op(Na, Nb)
        end
    end

end
+(d1::IMatrix{Na, Ta}, d2::IMatrix{Nb, Tb}) where {Na, Nb, Ta, Tb} = d1==d2 ? Diagonal(fill(promote_types(Ta, Tb)(2), Na)) : throw(DimensionMismatch())
-(d1::IMatrix{Na, Ta}, d2::IMatrix{Nb, Tb}) where {Na, Ta, Nb, Tb} = d1==d2 ? spzeros(promote_types(Ta, Tb), Na, Na) : throw(DimensionMismatch())
