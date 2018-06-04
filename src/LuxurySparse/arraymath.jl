import Base: conj, copy, real, ctranspose, imag
import Compat.LinearAlgebra: transpose, transpose!, ctranspose!


# Identity
for func in (:conj, :real, :ctranspose, :transpose, :copy)
    @eval ($func)(M::Identity{N, T}) where {N, T} = Identity{N, T}()
end
for func in (:ctranspose!, :transpose!)
    @eval ($func)(M::Identity) = M
end
imag(M::Identity{N, T}) where {N, T} = Diagonal(zeros(T,N))

# PermMatrix
for func in (:conj, :real, :imag)
    @eval ($func)(M::PermMatrix) = PermMatrix(M.perm, ($func)(M.vals))
end
copy(M::PermMatrix) = PermMatrix(copy(M.perm), copy(M.vals))

function transpose(M::PermMatrix)
    new_perm = invperm(M.perm)
    return PermMatrix(new_perm, M.vals[new_perm])
end

adjoint(S::PermMatrix{<:Real}) = transpose(S)
adjoint(S::PermMatrix{<:Complex}) = conj(transpose(S))


# scalar
import Base: *, /, ==, +, -, ≈
*(A::Identity{N, T}, B::Number) where {N, T} = Diagonal(fill(promote_type(T, eltype(B))(B), N))
*(B::Number, A::Identity{N, T}) where {N, T} = Diagonal(fill(promote_type(T, eltype(B))(B), N))
/(A::Identity{N, T}, B::Number) where {N, T} = Diagonal(fill(promote_type(T, eltype(B))(1/B), N))

*(A::PermMatrix, B::Number) = PermMatrix(A.perm, A.vals*B)
*(B::Number, A::PermMatrix) = A*B
/(A::PermMatrix, B::Number) = PermMatrix(A.perm, A.vals/B)
#+(A::PermMatrix, B::PermMatrix) = PermMatrix(A.dv+B.dv, A.ev+B.ev)
#-(A::PermMatrix, B::PermMatrix) = PermMatrix(A.dv-B.dv, A.ev-B.ev)


const IDP = Union{Diagonal, PermMatrix, Identity}
for op in [:+, :-, :(==), :≈]

    @eval begin
        $op(A::IDP, B::SparseMatrixCSC) = $op(sparse(A), B)
        $op(B::SparseMatrixCSC, A::IDP) = $op(B, sparse(A))

        # intra-IDP
        $op(A::PermMatrix, B::IDP) = $op(sparse(A), sparse(B))
        $op(A::IDP, B::PermMatrix) = $op(sparse(A), sparse(B))
        $op(A::PermMatrix, B::PermMatrix) = $op(sparse(A), sparse(B))
    end

    # intra-ID
    if op in [:+, :-]
        @eval begin
            $op(d1::Diagonal, d2::Identity) = Diagonal($op(d1.diag, diag(d2)))
            $op(d1::Identity, d2::Diagonal) = Diagonal($op(diag(d1), d2.diag))
        end
    else
        @eval begin
            $op(d1::Identity, d2::Diagonal) = $op(diag(d1), d2.diag)
            $op(d1::Diagonal, d2::Identity) = $op(d1.diag, diag(d2))
            $op(d1::Identity{Na}, d2::Identity{Nb}) where {Na, Nb} = $op(Na, Nb)
        end
    end

end
+(d1::Identity{Na, Ta}, d2::Identity{Nb, Tb}) where {Na, Nb, Ta, Tb} = d1==d2 ? Diagonal(fill(promote_types(Ta, Tb)(2), Na)) : throw(DimensionMismatch())
-(d1::Identity{Na, Ta}, d2::Identity{Nb, Tb}) where {Na, Ta, Nb, Tb} = d1==d2 ? spzeros(promote_types(Ta, Tb), Na, Na) : throw(DimensionMismatch())

