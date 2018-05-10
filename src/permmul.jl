"""
Multiply and permute sparse matrix
"""
struct PermuteMultiply{Tv, Ti<:Integer} <: AbstractMatrix{Tv, Ti}
    perm::Vector{Ti}   # new orders
    vals::Vector{Tv}  # multiplied values.

    function PermuteMultiply{Tv, Ti}(perm::Vector{Ti}, vals::Vector{Tv}) where {Tv, Ti<:Integer}
        if length(perm) != length(vals)
            throw(DimensionMismatch("permutation ($(length(perm))) and multiply ($(length(vals))) length mismatch."))
        end
        new{Tv, Ti}(perm, vals)
    end
end

function PermuteMultiply(perm::Vector, vals::Vector)
    Tv = eltype(vals)
    Ti = eltype(perm)
    PermuteMultiply{Tv,Ti}(perm, vals)
end

import Base: size, show
size(M::PermuteMultiply) = (length(M.perm), length(M.perm))
function size(A::PermuteMultiply, d::Integer)
    if d < 1
        throw(ArgumentError("dimension must be ≥ 1, got $d"))
    elseif d<=2
        return length(A.perm)
    else
        return 1
    end
end

function Matrix{T}(M::PermuteMultiply) where T
    n = size(M, 1)
    Mf = zeros(T, n, n)
    Mf[i, M.perm] = M.vals
    return Mf
end
Matrix(M::PermuteMultiply{T}) where {T} = Matrix{T}(M)
Array(M::PermuteMultiply) = Matrix(M)

#Elementary operations
for func in (:conj, :real, :imag)
    @eval ($func)(M::PermuteMultiply) = PermuteMultiply(M.perm, ($func)(M.vals))
end
copy(M::PermuteMultiply) = PermuteMultiply(copy(M.perm), ($func)(M.vals))

function transpose(M::PermuteMultiply)
    new_perm = sortperm(M.perm)
    return PermuteMultiply(new_perm, M.vals[new_perm])
end

adjoint(S::PermuteMultiply{<:Real}) = transpose(S)
adjoint(S::PermuteMultiply) = Adjoint(S)
Base.copy(S::Adjoint{<:Any,<:PermuteMultiply}) = PermuteMultiply(map(x -> copy.(adjoint.(x)), (S.parent.perm, S.parent.vals))...)
Base.copy(S::Transpose{<:Any,<:PermuteMultiply}) = PermuteMultiply(map(x -> copy.(transpose.(x)), (S.parent.perm, S.parent.vals))...)

*(A::PermuteMultiply, B::Number) = PermuteMultiply(A.perm, A.vals*B)
*(B::Number, A::PermuteMultiply) = A*B
/(A::PermuteMultiply, B::Number) = PermuteMultiply(A.perm, A.vals/B)
==(A::PermuteMultiply, B::PermuteMultiply) = (A.perm==B.perm) && (A.vals==B.vals)

#+(A::PermuteMultiply, B::PermuteMultiply) = PermuteMultiply(A.dv+B.dv, A.ev+B.ev)
#-(A::PermuteMultiply, B::PermuteMultiply) = PermuteMultiply(A.dv-B.dv, A.ev-B.ev)

#nnz(M::PermuteMultiply) = length()
#nonzeros(pred) = M.vals

function show(io::IOContext, M::PermuteMultiply)
    println("PermuteMultiply")
    for item in zip(M.perm, M.vals)
        i, p = item
        print("* $p -> $i")
    end
end

getindex(M::PermuteMultiply, i::Integer, j::Integer) = M.perm[i] == j ? M.vals[i] : 0
function inv(M::PermuteMultiply)
    new_perm = sortperm(M.perm)
    return PermuteMultiply(new_perm, 1.0/M.vals[new_perm])
end

function mul!(C::StridedVecOrMat, S::PermuteMultiply, B::StridedVecOrMat)
    m, n = size(B, 1), size(B, 2)
    if !(m == size(S, 1) == size(C, 1))
        throw(DimensionMismatch("A has first dimension $(size(S,1)), B has $(size(B,1)), C has $(size(C,1)) but all must match"))
    end
    if n != size(C, 2)
        throw(DimensionMismatch("second dimension of B, $n, doesn't match second dimension of C, $(size(C,2))"))
    end

    perm = S.perm
    vals = S.vals
    @inbounds begin
        for j = 1:n
            x₀, x₊ = B[1, j], B[2, j]
            β₀ = vals[1]
            C[1, j] = perm[1]*x₀ + x₊*β₀
            for i = 2:m - 1
                x₋, x₀, x₊ = x₀, x₊, B[i + 1, j]
                β₋, β₀ = β₀, vals[i]
                C[i, j] = vals₋*x₋ + perm[i]*x₀ + β₀*x₊
            end
            C[m, j] = β₀*x₀ + perm[m]*x₊
        end
    end

    return C
end

############################ Tests ##########################
using Compat.Test

@testset "Basic" begin
    mp = PermuteMultiply(4, [2, 1, 4, 3], [0.1, 0.3, 0.2, 0.3im])
    #println(mp)

    vec = [1, 2, 3, 4]
    target_vec = [0.2, 0.3, 0.8, 0.9im]
    @test mp * vec == target_vec

    # test inv
    invmp = inv(mp)
    @test isapprox(invmp * target_vec, vec)
end
