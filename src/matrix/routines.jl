using SparseArrays, LuxurySparse

"""
    cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::AbstractMatrix, locs::NTuple{M, Int}) where {C, M} -> AbstractMatrix

control-unitary matrix
"""
function cunmat end

"""
    u1ij!(target, i, j, a, b, c, d)
single u1 matrix into a target matrix.

!!! note
    For coo, we take an additional parameter
        * ptr: starting position to store new data.
"""
function u1ij! end

"""
    setcol!(csc::SparseMatrixCSC, icol::Int, rowval::AbstractVector, nzval) -> SparseMatrixCSC

set specific col of a CSC matrix
"""
@inline function setcol!(csc::SparseMatrixCSC, icol::Int, rowval::AbstractVector, nzval)
    @inbounds begin
        S = csc.colptr[icol]
        E = csc.colptr[icol+1]-1
        csc.rowval[S:E] = rowval
        csc.nzval[S:E] = nzval
    end
    csc
end

"""
    getcol(csc::SDparseMatrixCSC, icol::Int) -> (View, View)

get specific col of a CSC matrix, returns a slice of (rowval, nzval)
"""
@inline function getcol(csc::SDSparseMatrixCSC, icol::Int)
    @inbounds begin
        S = csc.colptr[icol]
        E = csc.colptr[icol+1]-1
        view(csc.rowval, S:E), view(csc.nzval, S:E)
    end
end

@inline function reorderU_iterator(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::AbstractMatrix, locs::NTuple{M, Int}) where {C, M}
    # reorder a unirary matrix.
    U = all(diff(locs).>0) ? U0 : reorder(U0, collect(locs)|>sortperm)
    locked_bits = [cbits..., locs...]
    locked_vals = [cvals..., zeros(Int, M)...]
    locs_raw = [i+1 for i in itercontrol(nbit, setdiff(1:nbit, locs), zeros(Int, nbit-M))]
    ic = itercontrol(nbit, locked_bits, locked_vals)
    return U |> staticize, ic, locs_raw |> staticize
end

cunmat(nbit::Int, cbits::NTuple, cvals::NTuple, U::IMatrix, locs::NTuple) = IMatrix{1<<nbit}()

"""
    unmat(nbit::Int, U::AbstractMatrix, locs::NTuple) -> AbstractMatrix

Return the matrix representation of putting matrix at locs.
"""
unmat(nbit::Int, U::AbstractMatrix, locs::NTuple) = cunmat(nbit::Int, (), (), U, locs)

############################### Dense Matrices ###########################
u1mat(nbit::Int, U1::AbstractMatrix, ibit::Int) = unmat(nbit, U1, (ibit,))

function u1mat(nbit::Int, U1::SDMatrix, ibit::Int)
    mask = bmask(ibit)
    N = 1<<nbit
    a, c, b, d = U1
    step = 1<<(ibit-1)
    step_2 = 1<<ibit
    mat = SparseMatrixCSC(N, N, collect(1:2:2*N+1), Vector{Int}(undef, 2*N), Vector{eltype(U1)}(undef, 2*N))
    for j = 0:step_2:N-step
        @inbounds @simd for i = j+1:j+step
            u1ij!(mat, i, i+step, a, b, c, d)
        end
    end
    mat
end

@inline function u1ij!(csc::SparseMatrixCSC, i::Int,j::Int, a, b, c, d)
    @inbounds begin
        csc.rowval[2*i-1] = i
        csc.rowval[2*i] = j
        csc.rowval[2*j-1] = i
        csc.rowval[2*j] = j

        csc.nzval[2*i-1] = a
        csc.nzval[2*i] = c
        csc.nzval[2*j-1] = b
        csc.nzval[2*j] = d
    end
    csc
end

@inline function unij!(mat::SparseMatrixCSC, locs, U::SDMatrix)
   @simd for j = 1:size(U, 2)
        @inbounds setcol!(mat, locs[j], locs, view(U,:,j))
    end
    csc
end

function cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::SDMatrix, locs::NTuple{M, Int}) where {C, M}
    U, ic, locs_raw = reorderU_iterator(nbit, cbits, cvals, U0, locs)
    N = 1<<nbit
    MM = size(U0, 1)
    NNZ = 1<<nbit + length(ic) * (length(U0) - size(U0,2))

    colptr = Vector{Int}(undef, N+1)
    rowval = Vector{Int}(undef, NNZ)
    colptr[1] = 1

    ctest = controller(cbits, cvals)
    @inbounds @simd for b in basis(nbit)
        if ctest(b)
            colptr[b+2] = colptr[b+1] + MM
        else
            colptr[b+2] = colptr[b+1] + 1
            rowval[colptr[b+1]] = b+1
        end
    end
    mat = SparseMatrixCSC(N, N, colptr, rowval, ones(eltype(U), NNZ))

    controldo(ic) do i
        unij!(mat, locs_raw+i, U)
    end
    mat
end



############################### SparseMatrix ##############################
function cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::SparseMatrixCSC{Tv}, locs::NTuple{M, Int})::SparseMatrixCSC{Tv} where {C, M, Tv}
    U, ic, locs_raw = reorderU_iterator(nbit, cbits, cvals, U0, locs)
    N = 1<<nbit
    NNZ::Int = 1<<nbit + length(ic) * (nnz(U0) - size(U0,2))
    ns = diff(U.colptr) |> autostatic

    rowval = Vector{Int}(undef, NNZ)
    colptr = Vector{Int}(undef, N+1)

    Ns = ones(Int, N)
    controldo(ic) do i
        @inbounds Ns[locs_raw + i] = ns
    end
    colptr[1] = 1
    @inbounds @simd for j = 1:N
        colptr[j+1] = colptr[j] + Ns[j]
        if Ns[j] == 1
            rowval[colptr[j]] = j
        end
    end

    mat = SparseMatrixCSC(N, N, colptr, rowval, ones(Tv, NNZ))
    controldo(ic) do i
        unij!(mat, locs_raw+i, U)
    end
    mat
end

@inline function unij!(mat::SparseMatrixCSC, locs, U::SDSparseMatrixCSC)
    @simd for j = 1:size(U, 2)
        rows, vals = getcol(U, j)
        @inbounds setcol!(mat, locs[j], view(locs, rows), vals)
    end
    csc
end

############################# PermMatrix ###############################
@inline function unij!(pm::PermMatrix, locs::AbstractVector, U::SDPermMatrix)
    M = size(U, 1)
    @inbounds pm.perm[locs] = locs[U.perm]
    @inbounds pm.vals[locs] = U.vals
    return pm
end

function cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::SDPermMatrix, locs::NTuple{M, Int}) where {C, M}
    U, ic, locs_raw = reorderU_iterator(nbit, cbits, cvals, U0, locs)
    N = 1<<nbit
    pm = PermMatrix(collect(1:N), ones(eltype(U), N))
    controldo(ic) do i
        unij!(pm, locs_raw+i, U)
    end
    return pm
end

############################ Diagonal ##########################
function cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::SDDiagonal, locs::NTuple{M, Int}) where {C, M}
    U, ic, locs_raw = reorderU_iterator(nbit, cbits, cvals, U0, locs)
    dg = Diagonal(ones(eltype(U0), 1<<nbit))
    controldo(ic) do i
        unij!(dg, locs_raw+i, U)
    end
    return dg
end

@inline function unij!(dg::SDDiagonal, locs, U)
    @inbounds dg.diag[locs] = U.diag
    return dg
end
