IMatrix{N, T}(::IMatrix) where {N, T} = IMatrix{N, T}()
IMatrix{T}(A::AbstractMatrix) where T = IMatrix{size(A, 1) == size(A,2) ? size(A, 2) : throw(DimensionMismatch()), T}()
IMatrix(x::AbstractMatrix{T}) where T = IMatrix{T}(x)

SparseMatrixCSC{Tv, Ti}(A::IMatrix{N}) where {Tv, Ti <: Integer, N} = SparseMatrixCSC{Tv, Ti}(I, N, N)
SparseMatrixCSC{Tv}(A::IMatrix) where Tv = SparseMatrixCSC{Tv, Int}(A)
SparseMatrixCSC(A::IMatrix{N, T}) where {N, T} = SparseMatrixCSC{T, Int}(I, N, N)
Diagonal{T}(::IMatrix{N}) where {T, N} = Diagonal{T}(ones(T, N))
Diagonal(::IMatrix{N, T}) where {N, T} = Diagonal{T}(ones(T, N))

Matrix{T}(::IMatrix{N}) where {T, N} = Matrix{T}(I, N, N)
Matrix(::IMatrix{N, T}) where {N, T} = Matrix{T}(I, N, N)

PermMatrix{Tv, Ti}(::IMatrix{N}) where {Tv, Ti, N} = PermMatrix{Tv, Ti}(Vector{Ti}(1:N), ones(Tv, N))
PermMatrix{Tv}(X::IMatrix) where Tv = PermMatrix{Tv, Int}(X)
PermMatrix(X::IMatrix{N, T}) where {N, T} = PermMatrix{T, Int}(X)

function Matrix{T}(X::PermMatrix) where T
    n = size(X, 1)
    Mf = zeros(T, n, n)
    @inbounds for i=1:n
        Mf[i, X.perm[i]] = X.vals[i]
    end
    return Mf
end

PermMatrix{Tv, Ti}(A::PermMatrix) where {Tv, Ti} = PermMatrix(Vector{Ti}(A.perm), Vector{Tv}(A.vals))

function PermMatrix{Tv, Ti}(A::AbstractMatrix) where {Tv, Ti}
    i,j,v = findnz(A)
    j == collect(1:size(A, 2)) || throw(ArgumentError("This is not a PermMatrix"))
    order = invperm(i)
    PermMatrix{Tv, Ti}(Vector{Ti}(order), Vector{Tv}(v[order]))
end

PermMatrix(A::AbstractMatrix{T}) where T = PermMatrix{T, Int}(A)
PermMatrix(A::SparseMatrixCSC{Tv, Ti}) where {Tv, Ti} = PermMatrix{Tv, Ti}(A) # inherit indice type

PermMatrix{Tv, Ti}(A::Diagonal) where {Tv, Ti} = PermMatrix(Vector{Ti}(1:size(A, 1)), Vector{Tv}(A.diag))
PermMatrix(A::Diagonal{T}) where T = PermMatrix{T, Int}(A)

import Base: convert
convert(T::Type{<:PermMatrix}, m::AbstractMatrix) = m isa T ? m : T(m)
convert(T::Type{<:IMatrix}, m::AbstractMatrix) = m isa T ? m : T(m)
convert(T::Type{<:Diagonal}, m::AbstractMatrix) = m isa T ? m : T(m)
