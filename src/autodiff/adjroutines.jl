@inline function adjunij!(mat::AbstractMatrix, locs, U::Matrix)
    for j = 1:size(U, 2)
        for i = 1:size(U, 2)
            @inbounds U[i,j] += mat[locs[i],locs[j]]
        end
    end
    return U
end

@inline function adjunij!(mat::AbstractMatrix, locs, U::SparseMatrixCSC)
    @inbounds for j = 1:size(U, 2)
        S = U.colptr[j]
        E = U.colptr[j+1]-1
        for ii = S:E
            @inbounds U.nzval[ii] += mat[locs[U.rowval[ii]],locs[j]]
        end
    end
    return U
end

@inline function adjunij!(mat::SDDiagonal, locs, U::Diagonal)
    @inbounds U.diag .+= mat.diag[locs]
    return U
end

@inline function adjunij!(mat::AbstractMatrix, locs, U::Diagonal)
    @inbounds for i=1:size(U,1)
        li = locs[i]
        U.diag[i] += mat[li, li]
    end
    return U
end

@inline function adjunij!(mat::SDPermMatrix, locs, U::PermMatrix)
    @inbounds U.vals .+= mat.vals[locs]
    return U
end

@inline function adjunij!(mat::AbstractMatrix, locs, U::PermMatrix)
    for i=1:size(U, 1)
        @inbounds U.vals[i] += mat[locs[i], locs[U.perm[i]]]
    end
    return U
end

function adjcunmat(adjy::AbstractMatrix, nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::AbstractMatrix{T}, locs::NTuple{M, Int}) where {C, M, T}
    U, ic, locs_raw = YaoBlocks.reorder_unitary(nbit, cbits, cvals, U0, locs)
    adjU = _render_adjU(U)

    controldo(ic) do i
        adjunij!(adjy, locs_raw+i, adjU)
    end

    adjU = all(diff([locs...]).>0) ? adjU : YaoBase.reorder(adjU, collect(locs)|>sortperm|>sortperm)
    adjU
end

@inline function adju1ij!(csc::SparseMatrixCSC{T}, i::Int,j::Int, adjU::Matrix) where T
    @inbounds begin
        adjU[1,1] += csc.nzval[2*i-1]
        adjU[1,2] += csc.nzval[2*i]
        adjU[2,1] += csc.nzval[2*j-1]
        adjU[2,2] += csc.nzval[2*j]
    end
    adjU
end

function adju1mat(adjy, nbit::Int, U1::SDMatrix, ibit::Int)
    mask = bmask(ibit)
    step = 1<<(ibit-1)
    step_2 = 1<<ibit

    adjy = projection(YaoBlocks._initialize_output(nbit, 0, U1), adjy)
    adjU = _render_adjU(U1)

    for j = 0:step_2:1<<nbit-step
        @inbounds @simd for i = j+1:j+step
            adju1ij!(adjy, i, i+step, adjU)
        end
    end
    adjU
end

_render_adjU(U0::AbstractMatrix{T}) where T = zeros(T, size(U0)...)
_render_adjU(U0::SDSparseMatrixCSC{T}) where T = SparseMatrixCSC(size(U0)..., dynamicize(U0.colptr), dynamicize(U0.rowval), zeros(T, U0.nzval|>length))
_render_adjU(U0::SDDiagonal{T}) where T = Diagonal(zeros(T, size(U0, 1)))
_render_adjU(U0::SDPermMatrix{T}) where T = PermMatrix(U0.perm, zeros(T, length(U0.vals)))

# DEPRECATED
#=
@inline function adjsetcol!(csc::SparseMatrixCSC, icol::Int, rowval::AbstractVector, nzval::SubArray)
    begin
        S = csc.colptr[icol]
        E = csc.colptr[icol+1]-1
        nzval .+= view(csc.nzval, S:E)
    end
    csc
end

@inline function adjunij!(mat::SparseMatrixCSC, locs, U::Matrix)
    for j = 1:size(U, 2)
        adjsetcol!(mat, locs[j], locs, view(U,:,j))
    end
    return U
end

@inline function adjunij!(mat::SparseMatrixCSC, locs, U::SparseMatrixCSC)
    for j = 1:size(U, 2)
        S = U.colptr[j]
        E = U.colptr[j+1]-1
        @inbounds adjsetcol!(mat, locs[j], locs, view(U.nzval,S:E))
    end
    return U
end
=#
