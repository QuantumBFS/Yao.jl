import Base: promote_rule

# SparseMatrixCSC
promote_rule(::Type{SparseMatrixCSC{Tv, Ti}}, ::Type{Matrix{T}}) where {Tv, Ti, T} = Matrix{promote_type(T, Tv)}

# Identity
promote_rule(::Type{Identity{N, T}}, ::Type{PermMatrix{Tv, Ti}}) where {N, T, Tv, Ti} = PermMatrix{promote_type(T, Tv), Ti}
promote_rule(::Type{Identity{N, T}}, ::Type{SparseMatrixCSC{Tv, Ti}}) where {N, T, Tv, Ti} = SparseMatrixCSC{promote_type(T, Tv), Ti}
promote_rule(::Type{Identity{M, TA}}, ::Type{Matrix{TB}}) where {M, TA, TB} = Array{TB, 2}

# PermMatrix
promote_rule(::Type{PermMatrix{TvA, TiA}}, ::Type{SparseMatrixCSC{TvB, TiB}}) where {TvA, TiA, TvB, TiB} =
    SparseMatrixCSC{promote_type(TvA, TvB), promote_type(TiA, TiB)}
promote_rule(::Type{PermMatrix{Tv, Ti}}, ::Type{Matrix{T}}) where {Tv, Ti, T} =
    Array{promote_type(Tv, T), 2}

# Diagonal
@static if VERSION < v"0.7-"
promote_rule(::Type{Identity{N, TA}}, ::Type{Diagonal{TB}}) where {N, TA, TB} = Diagonal{promote_type(TA, TB)}
promote_rule(::Type{Diagonal{Tv}}, ::Type{Matrix{T}}) where {Tv, T} = Matrix{promote_type(Tv, T)}
promote_rule(::Type{Diagonal{T}}, ::Type{SparseMatrixCSC{Tv, Ti}}) where {T, Tv, Ti} = SparseMatrixCSC{promote_type(T, Tv), Ti}
else
# TODO: support this promotion for v0.7
end
