####### conversions #######
import Base: convert
convert(::Type{Identity{N, T}}, ::Identity) where {N, T} = Identity{N, T}()

convert(::Type{SparseMatrixCSC{Tv, Ti}}, src::Identity{N}) where {Tv, Ti <: Integer, N} = SparseMatrixCSC{Tv, Ti}(SparseArrays.I, N, N)
convert(::Type{Array{T}}, src::Identity{N}) where {T, N} = Array{T}(LinearAlgebra.I, N, N)
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
