function u1apply!(state::VecOrMat{T}, U1::AbstractMatrix, ibit::Int) where T
    mask = bmask(ibit)
    a, c, b, d = U1
    step = 1<<(ibit-1)
    step_2 = 1<<ibit
    for j = 0:step_2:size(state, 1)-step
        @inbounds @simd for i = j+1:j+step
            u1rows!(state, i, i+step, a, b, c, d)
        end
    end
    state
end

#=
function unapply!(state::VecOrMat, U::AbstractMatrix, locs::Vector{Int})
    nbit, Nu, nu = nqubits(state), size(U, 1), length(locs)
    #Nu == 1<<nu || throw(DimensionMismatch("Unitary Matrix shape does not macth locations to apply"))
    locs_raw = [i+1 for i in itercontrol(nbit, setdiff(1:nbit, locs), zeros(Int, nbit-nu))]
    ic = itercontrol(nbit, locs, zeros(Int, length(locs)))
    Nu <=16 ? _unapply!(state, SMatrix{Nu, Nu}(U), SVector{Nu}(locs_raw), ic) : _unapply!(state, U, locs_raw, ic)
end
=#

function _unapply!(state::VecOrMat, U::Union{SMatrix, Matrix}, locs_raw::Union{SVector, Vector}, ic::IterControl)
    controldo(ic) do i
        unrows!(state, locs_raw+i, U)
    end
    state
end

"""
control-unitary 
"""
function cunapply!(state::VecOrMat, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U::AbstractMatrix, locs::NTuple{M, Int}) where {C, M}
    # reorder a unirary matrix.
    U = all(diff(locs).>0) ? U : reorder(U, collect(locs)|>sortperm)
    N, MM = nqubits(state), size(U, 1)
    locked_bits = [cbits..., locs...]
    locked_vals = [cvals..., zeros(Int, M)...]
    locs_raw = [i+1 for i in itercontrol(N, setdiff(1:N, locs), zeros(Int, N-M))]
    ic = itercontrol(N, locked_bits, locked_vals)
    MM <=16 ? _unapply!(state, SMatrix{MM, MM}(U), SVector{MM}(locs_raw), ic) : _unapply!(state, U, locs_raw, ic)
end

unapply!(state::VecOrMat, U::AbstractMatrix, locs::NTuple) = cunapply!(state, (), (), U, locs)
