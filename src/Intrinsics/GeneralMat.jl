function u1mat(nbit::Int, U1::AbstractMatrix{T}, ibit::Int) where T
    mask = bmask(ibit)
    N = 1<<nbit
    coo = allocated_coo(T, 2*N)
    a, c, b, d = U1
    step = 1<<(ibit-1)
    step_2 = 1<<ibit
    for j = 0:step_2:N-step
        @inbounds @simd for i = j+1:j+step
            u1ij!(coo, i, i+step, a, b, c, d)
        end
    end
    sparse(coo..., N, N)
end

function _unmat(nbit::Int, U::Union{SMatrix, Matrix}, locs_raw::Union{SVector, Vector}, ic::IterControl)
    nr = size(U, 1)
    coo = allocated_coo(T, nr*N)
    controldo(ic) do i
        unij!(coo, locs_raw+i, U)
    end
    sparse(coo..., N, N)
end

function _unmat(nbit::Int, U::Union{SDiagonal, Diagonal}, locs_raw::Union{SVector, Vector}, ic::IterControl)
    dg = Diagonal(Vector{T}(1<<nbit))
    controldo(ic) do i
        unij!(dg, locs_raw+i, U)
    end
    dg
end

function _unmat(nbit::Int, U::PermMatrix, locs_raw::Union{SVector, Vector}, ic::IterControl)
    N = 1<<nbit
    pm = PermMatrix(Vector{Int}(N), Vector{T}(N))
    controldo(ic) do i
        unij!(pm, locs_raw+i, U)
    end
    dg
end

function _unmat(nbit::Int, U::Union{SSparseMatrixCSC, SparseMatrixCSC}, locs_raw::Union{SVector, Vector}, ic::IterControl)
    coo = allocated_coo(T, N, N÷size(U, 1)*length(U.nzval))
    controldo(ic) do i
        unij!(coo, locs_raw+i, U)
    end
    sparse(coo..., N, N)
end


"""
turn a vector/matrix to static vector/matrix (only if its length <= 256).
"""
autostatic(A::AbstractVecOrMat) = length(A) > 1<<8 ? A : A |> statify

"""
control-unitary 
"""
function cunmat end

function cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U::AbstractMatrix, locs::NTuple{M, Int}) where {C, M}
    # reorder a unirary matrix.
    U = all(diff(locs).>0) ? U : reorder(U, collect(locs)|>sortperm)
    N, MM = nqubits(state), size(U, 1)
    locked_bits = [cbits..., locs...]
    locked_vals = [cvals..., zeros(Int, M)...]
    locs_raw = [i+1 for i in itercontrol(N, setdiff(1:N, locs), zeros(Int, N-M))]
    ic = itercontrol(N, locked_bits, locked_vals)
    _unmat(nbit, U |> autostatic, locs_raw |> autostatic, ic)
end

cunmat(nbit::Int, cbits::NTuple, cvals::NTuple, U::IMatrix, locs::NTuple) = IMatrix{1<<nbit}()

unmat(nbit::Int, U::AbstractMatrix, locs::NTuple) = cunmat(nbit::Int, (), (), U, locs)
