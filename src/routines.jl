using SparseArrays, LuxurySparse
import YaoBase: diff, autostatic

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
        E = csc.colptr[icol+1] - 1
        csc.rowval[S:E] = rowval
        csc.nzval[S:E] = nzval
    end
    csc
end

"""
    num_nonzero(nbits, nctrls, U)

Return number of nonzero entries of the matrix form of control-U gate. `nbits`
is the number of qubits, and `nctrls` is the number of control qubits.
"""
@inline function num_nonzero(nbits::Int, nctrls::Int, U, N::Int = 1 << nbits)
    return N + (1 << (nbits - nctrls - log2dim1(U))) * (length(U) - size(U, 2))
end

@inline function num_nonzero(nbits::Int, U, N::Int = 1 << nbits)
    return N + (1 << (nbits - log2dim1(U))) * (length(U) - size(U, 2))
end

"""
    getcol(csc::SDparseMatrixCSC, icol::Int) -> (View, View)

get specific col of a CSC matrix, returns a slice of (rowval, nzval)
"""
@inline function getcol(csc::SDSparseMatrixCSC, icol::Int)
    @inbounds begin
        S = csc.colptr[icol]
        E = csc.colptr[icol+1] - 1
        view(csc.rowval, S:E), view(csc.nzval, S:E)
    end
end

@inline function reorder_unitary(
    nbit::Int,
    cbits::NTuple{C,Int},
    cvals::NTuple{C,Int},
    U0::AbstractMatrix,
    locs::NTuple{M,Int},
) where {C,M}
    # reorder a unirary matrix.
    U = all(diff(locs) .> 0) ? U0 : reorder(U0, collect(locs) |> sortperm)
    locked_bits = [cbits..., locs...]
    locked_vals = [cvals..., zeros(Int, M)...]
    locs_raw = [i + 1 for i in itercontrol(nbit, setdiff(1:nbit, locs), zeros(Int, nbit - M))]
    ic = itercontrol(nbit, locked_bits, locked_vals)
    return U |> autostatic, ic, locs_raw |> staticize
end

adaptive_pow2(n::Int) = adaptive_pow2(UInt(n))

function adaptive_pow2(n::UInt)
    n < 62 ? Int64(1) << n : n < 126 ? Int128(1) << n : big(1) << n
end

const LARGE_MATRIX_WARN = 62

function large_mat_check(n::Int)
    if n > LARGE_MATRIX_WARN
        error("matrix is too large, expect n <= $LARGE_MATRIX_WARN, got $n, integer overflows")
    end
    return nothing
end

function cunmat(n::Int, cbits::NTuple, cvals::NTuple, U::IMatrix, locs::NTuple)
    large_mat_check(n)
    IMatrix{1 << n}()
end

"""
    unmat(nbit::Int, U::AbstractMatrix, locs::NTuple) -> AbstractMatrix

Return the matrix representation of putting matrix at locs.
"""
function unmat(nbit::Int, U::AbstractMatrix, locs::NTuple)
    large_mat_check(nbit)
    cunmat(nbit::Int, (), (), U, locs)
end

############################### Dense Matrices ###########################
function u1mat(nbit::Int, U1::AbstractMatrix, ibit::Int)
    large_mat_check(nbit)
    unmat(nbit, U1, (ibit,))
end

u1mat(nbit::Int, U1::Adjoint, ibit::Int) = u1mat(nbit, copy(U1), ibit)

function u1mat(nbits::Int, U1::SDMatrix, ibit::Int)
    large_mat_check(nbits)
    mask = bmask(ibit)
    N = 1 << nbits
    a, c, b, d = U1
    step = 1 << (ibit - 1)
    step_2 = 1 << ibit
    NNZ = num_nonzero(nbits, U1, N)

    colptr = Vector{Int}(1:2:2*N+1)
    rowval = Vector{Int}(undef, NNZ)
    nzval = Vector{eltype(U1)}(undef, NNZ)

    mat = SparseMatrixCSC(N, N, colptr, rowval, nzval)
    for j = 0:step_2:N-step
        @inbounds @simd for i = j+1:j+step
            u1ij!(mat, i, i + step, a, b, c, d)
        end
    end
    return mat
end

@inline function u1ij!(csc::SparseMatrixCSC, i::Int, j::Int, a, b, c, d)
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
        @inbounds setcol!(mat, locs[j], locs, view(U, :, j))
    end
    csc
end

function cunmat(
    nbit::Int,
    cbits::NTuple{C,Int},
    cvals::NTuple{C,Int},
    U0::Adjoint,
    locs::NTuple{M,Int},
) where {C,M}
    cunmat(nbit, cbits, cvals, copy(U0), locs)
end

function cunmat(
    nbit::Int,
    cbits::NTuple{C,Int},
    cvals::NTuple{C,Int},
    U0::SDMatrix,
    locs::NTuple{M,Int},
) where {C,M}
    large_mat_check(nbit)
    MM = size(U0, 1)
    U, ic, locs_raw = reorder_unitary(nbit, cbits, cvals, U0, locs)

    N = 1 << nbit
    NNZ = num_nonzero(nbit, C, U0, N)
    colptr = Vector{Int}(undef, N + 1)
    rowval = Vector{Int}(undef, NNZ)
    nzval = ones(eltype(U0), NNZ)

    @inbounds colptr[1] = 1
    ctest = controller(cbits, cvals)
    @inbounds @simd for b in basis(nbit)
        if ctest(b)
            colptr[b+2] = colptr[b+1] + MM
        else
            colptr[b+2] = colptr[b+1] + 1
            rowval[colptr[b+1]] = b + 1
        end
    end

    mat = SparseMatrixCSC(N, N, colptr, rowval, nzval)
    controldo(ic) do i
        unij!(mat, locs_raw + i, U)
    end
    return mat
end

############################### SparseMatrix ##############################
function cunmat(
    nbit::Int,
    cbits::NTuple{C,Int},
    cvals::NTuple{C,Int},
    U0::SparseMatrixCSC{Tv},
    locs::NTuple{M,Int},
)::SparseMatrixCSC{Tv} where {C,M,Tv}
    large_mat_check(nbit)
    N = 1 << nbit
    U, ic, locs_raw = reorder_unitary(nbit, cbits, cvals, U0, locs)

    NNZ = num_nonzero(nbit, C, U0, N)
    colptr = Vector{Int}(undef, N + 1)
    rowval = Vector{Int}(undef, NNZ)
    nzval = ones(eltype(U0), NNZ)
    @inbounds colptr[1] = 1

    ns = diff(U.colptr) |> autostatic
    Ns = ones(Int, N)
    controldo(ic) do i
        @inbounds Ns[locs_raw+i] = ns
    end
    @inbounds @simd for j = 1:N
        colptr[j+1] = colptr[j] + Ns[j]
        if Ns[j] == 1
            rowval[colptr[j]] = j
        end
    end

    mat = SparseMatrixCSC(N, N, colptr, rowval, nzval)
    controldo(ic) do i
        unij!(mat, locs_raw + i, U)
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

function _initialize_output(nbit::Int, nctrl::Int, U::SDPermMatrix{T}) where {T}
    N = 1 << nbit
    PermMatrix(collect(1:N), ones(T, N))
end

function cunmat(
    nbit::Int,
    cbits::NTuple{C,Int},
    cvals::NTuple{C,Int},
    U0::SDPermMatrix,
    locs::NTuple{M,Int},
) where {C,M}
    large_mat_check(nbit)
    U, ic, locs_raw = reorder_unitary(nbit, cbits, cvals, U0, locs)
    pm = _initialize_output(nbit, C, U0)
    controldo(ic) do i
        unij!(pm, locs_raw + i, U)
    end
    return pm
end

############################ Diagonal ##########################
function _initialize_output(nbit::Int, nctrl::Int, U::SDDiagonal{T}) where {T}
    Diagonal(ones(T, 1 << nbit))
end

function cunmat(
    nbit::Int,
    cbits::NTuple{C,Int},
    cvals::NTuple{C,Int},
    U0::SDDiagonal,
    locs::NTuple{M,Int},
) where {C,M}
    large_mat_check(nbit)
    U, ic, locs_raw = reorder_unitary(nbit, cbits, cvals, U0, locs)
    dg = _initialize_output(nbit, C, U0)
    controldo(ic) do i
        unij!(dg, locs_raw + i, U)
    end
    return dg
end

@inline function unij!(dg::SDDiagonal, locs, U)
    @inbounds dg.diag[locs] = U.diag
    return dg
end
