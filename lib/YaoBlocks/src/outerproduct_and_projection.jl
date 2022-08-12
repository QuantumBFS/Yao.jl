export LowRankMatrix, OuterProduct, projection, outerprod
abstract type LowRankMatrix{T} <: AbstractMatrix{T} end

"""
$(TYPEDEF)

If `ATL(R) <: AbstractVector`, it represents an outer product `x.left*transpose(x.right)`.
Else if `ATL(R) <: AbstractMatrix`, then it is an outer product `x.left*transpose(x.right)`.
"""
struct OuterProduct{T,ATL<:AbstractArray{T},ATR<:AbstractArray{T}} <: LowRankMatrix{T}
    left::ATL
    right::ATR
    function OuterProduct(left::ATL, right::ATR) where {T,ATL<:AbstractArray{T},ATR<:AbstractArray{T}}
        size(left, 2) != size(right, 2) && throw(
            DimensionMismatch(
                "The seconds dimension of left ($(size(left,2))) and right $(size(right,2)) does not match.",
            ),
        )
        return new{T,ATL,ATR}(left, right)
    end
end

const BatchedOuterProduct{T,MTL,MTR} =
    OuterProduct{T,MTL,MTR} where {MTL<:AbstractMatrix,MTR<:AbstractMatrix}
const SimpleOuterProduct{T,VTL,VTR} =
    OuterProduct{T,VTL,VTR} where {VTL<:AbstractVector,VTR<:AbstractVector}

LinearAlgebra.rank(op::OuterProduct) = size(op.left, 2)
Base.getindex(op::OuterProduct{T,<:AbstractVector}, i::Int, j::Int) where {T} =
    op.left[i] * op.right[j]
Base.getindex(op::BatchedOuterProduct, i::Int, j::Int) =
    sum(k -> op.left[i, k] * op.right[j, k], 1:rank(op))
Base.size(op::OuterProduct) = (size(op.left, 1), size(op.right, 1))
Base.size(op::OuterProduct, i::Int) =
    i == 1 ? size(op.left, 1) : (i == 2 ? size(op.right, 1) : throw(DimensionMismatch("")))

Base.:(*)(a::OuterProduct, b::AbstractVector) = a.left * (transpose(a.right) * b)
Base.:(*)(a::OuterProduct, b::AbstractMatrix) =
    OuterProduct(a.left, transpose(transpose(a.right) * b))
Base.:(*)(a::AbstractMatrix, b::OuterProduct) = OuterProduct(a * b.left, b.right)
Base.:(*)(a::LinearAlgebra.AdjointAbsVec, b::OuterProduct) = (a * b.left) * transpose(b.right)
Base.:(*)(a::OuterProduct, b::OuterProduct) =
    OuterProduct(a.left * (transpose(a.right) * b.left), b.right)
LinearAlgebra.rmul!(a::OuterProduct, b::Number) = (rmul!(a.left, b); a)
Base.:(*)(a::Number, b::OuterProduct) = OuterProduct(a * b.left, b.right)
Base.:(*)(b::OuterProduct, a::Number) = a * b

Base.conj!(op::OuterProduct) = OuterProduct(conj!(op.left), conj!(op.right))
Base.transpose(op::OuterProduct) = OuterProduct(op.right, op.left)
Base.adjoint(op::OuterProduct) = OuterProduct(conj(op.right), conj(op.left))

outerprod(left::AbstractVector, right::AbstractVector) = OuterProduct(left, right)
outerprod(left::AbstractMatrix, right::AbstractMatrix) = OuterProduct(left, right)
outerprod(outδ::ArrayReg{D}, in::ArrayReg{D}) where D =
    outerprod(statevec(outδ), conj(statevec(in)))
outerprod(outδ::BatchedArrayReg{D}, in::BatchedArrayReg{D}) where {D} =
    outerprod(statevec(outδ), conj(statevec(in)))


"""
    projection(y::AbstractMatrix, op::AbstractMatrix) -> typeof(y)

Project `op` to sparse matrix with same sparsity as `y`.
"""
function projection(y::AbstractMatrix, op::AbstractMatrix)
    size(y) == size(op) || throw(
        DimensionMismatch(
            "can not project a matrix of size $(size(op)) to target size $(size(y))",
        ),
    )
    out = _zero(y)
    unsafe_projection!(out, op)
end
_zero(y) = y
_zero(y::SparseMatrixCSC) = SparseMatrixCSC(y.m, y.n, y.colptr, y.rowval, zero(y.nzval))

unsafe_projection!(y::Diagonal, m::AbstractMatrix) = (y.diag .= diag(m); y)
unsafe_projection!(y::Diagonal, op::OuterProduct) = (y.diag .+= op.left .* op.right; y)

unsafe_projection!(y::Matrix, adjy, v) = y .+= adjy .* v

@inline function unsafe_projection!(y::AbstractSparseMatrix, m::AbstractMatrix)
    is, js, vs = findnz(y)
    for (k, (i, j)) in enumerate(zip(is, js))
        @inbounds y.nzval[k] += m[i, j]
    end
    y
end

@inline function unsafe_projection!(y::PermMatrix, m::AbstractMatrix)
    for i = 1:size(y, 1)
        @inbounds y.vals[i] = m[i, y.perm[i]]
    end
    y
end

projection(x::RT, adjx::Complex) where {RT<:Real} = RT(real(adjx))
projection(x::T, y::T) where {T} = y
projection(x::T1, y::T2) where {T1,T2} = convert(T1, y)
