####### conversions #######
import Base: convert
convert(::Type{Identity{N, T}}, ::Identity) where {N, T} = Identity{N, T}()

convert(::Type{SparseMatrixCSC{Tv, Ti}}, src::Identity{N}) where {Tv, Ti <: Integer, N} = SparseMatrixCSC{Tv, Ti}(SparseArrays.I, N, N)
convert(::Type{Diagonal{T}}, src::Identity{N}) where {N, T} = Diagonal{T}(ones(T, N))
convert(::Type{Array{T}}, src::Identity{N}) where {T, N} = Array{T}(LinearAlgebra.I, N, N)
convert(::Type{PermMatrix{Tv, Ti}}, src::Identity{N}) where {N, Tv, Ti} = PermMatrix(Vector{Ti}(1:N), ones(Tv, N))
# TODO: conversion between CuArray

function convert(::Type{Matrix{T}}, X::PermMatrix) where T
    n = size(X, 1)
    Mf = zeros(T, n, n)
    @inbounds for i=1:n
        Mf[i, X.perm[i]] = X.vals[i]
    end
    return Mf
end

convert(::Type{PermMatrix{T}}, B::PermMatrix) where T = PermMatrix(B.perm, T.(B.vals))

function convert(::Type{PermMatrix}, ds::AbstractMatrix)
    i,j,v = findnz(ds)
    j == collect(1:size(ds, 2)) || throw(ArgumentError("This is not a PermMatrix"))
    order = invperm(i)
    PermMatrix(order, v[order])
end

convert(::Type{Identity{N, T}}, A::AbstractMatrix) where {N, T} = Identity{size(A, 1) == size(A,2) ? size(A, 2) : throw(DimensionMismatch()), T}()
