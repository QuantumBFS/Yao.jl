using BitBasis, LuxurySparse, StaticArrays
export instruct!

# TODO: control_bits -> control_locs
#       control_vals -> control_bits
const STATIC_THRESHOLD = 8
# to avoid potential ambiguity, we limit them to tuple for now
# but they only has to be an iterator over integers
const Locations{T} = NTuple{N, T} where N
const BitConfigs{T} = NTuple{N, T} where N

"""
    autostatic(A)

Staticize dynamic array `A` by a constant `STATIC_THRESHOLD`.
"""
autostatic(A::AbstractVecOrMat) = length(A) > (1 << _STATIC_THRESHOLD) ? A : staticize(A)

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    operator::AbstractMatrix{T},
    locs::NTuple{M, Int},
    control_bits::NTuple{C, Int} = (),
    control_vals::NTuple{C, Int} = ()) where {T, M, C}

    U = sort_unitary(operator, locs)
    N, MM = log2dim1(state), size(U, 1)

    locked_bits = (control_bits..., locs...)
    locked_vals = (control_vals..., (0 for k in 1:M)...)
    locs_raw = Tuple(b+1 for b in itercontrol(N, setdiff(1:N, locs), zeros(Int, N-M)))
    ic = itercontrol(N, locked_bits, locked_vals)
    return _instruct!(state, autostatic(U), SVector(locs_raw), ic)
end

function _instruct!(state::AbstractVecOrMat{T}, U::AbstractMatrix{T}, locs_raw::SVector, ic::IterControl) where T
    controldo(ic) do i
        unrows!(state, locs_raw .+ i, U)
    end
    return state
end

function _instruct!(state::AbstractVecOrMat{T}, U::SDSparseMatrixCSC{T}, locs_raw::SVector, ic::IterControl) where T
    work = ndims(state)==1 ? similar(state, length(locs_raw)) : similar(state, length(locs_raw), size(state,2))
    controldo(ic) do i
        unrows!(state, locs_raw .+ i, U, work)
    end
    return state
end

YaoBase.instruct!(state::AbstractVecOrMat, U::IMatrix, locs::NTuple{N, Int}) where N = state

# one-qubit instruction
YaoBase.instruct!(state::AbstractVecOrMat{T}, g::AbstractMatrix{T}, locs::Tuple{Int}) where T =
    instruct!(state, g, locs...)

function YaoBase.instruct!(state::AbstractVecOrMat{T}, U1::AbstractMatrix{T}, loc::Int) where T
    a, c, b, d = U1
    step = 1 << (loc - 1)
    step_2 = 1 << loc
    for j in 0:step_2:size(state, 1)-step
        @inbounds @simd for i in j+1:j+step
            u1rows!(state, i, i+step, a, b, c, d)
        end
    end
    return state
end

YaoBase.instruct!(state::AbstractVecOrMat{T}, g::SDPermMatrix{T}, locs::Tuple{Int}) where T =
    instruct!(state, g, locs...)

function YaoBase.instruct!(state::AbstractVecOrMat{T}, U1::SDPermMatrix{T}, loc::Int) where T
    U1.perm[1] == 1 && return instruct!(state, Diagonal(U1), loc)
    mask = bmask(loc)
    b, c = U1.vals
    step = 1<<(loc-1)
    step_2 = 1<<loc
    for j in 0:step_2:size(state, 1)-step
        @inbounds @simd for i in j+1:j+step
            swaprows!(state, i, i+step, c, b)
        end
    end
    return state
end

YaoBase.instruct!(state::AbstractVecOrMat{T}, g::SDDiagonal{T}, locs::Tuple{Int}) where T =
    instruct!(state, g, locs...)

function YaoBase.instruct!(state::AbstractVecOrMat{T}, U1::SDDiagonal{T}, loc::Int) where T
    mask = bmask(loc)
    a, d = U1.diag
    step = 1<<(loc - 1)
    step_2 = 1 << loc
    for j in 0:step_2:size(state, 1)-step
        @inbounds @simd for i in j+1:j+step
            mulrow!(state, i, a)
            mulrow!(state, i+step, d)
        end
    end
    return state
end

# specialization
# paulis
function YaoBase.instruct!(state::AbstractVecOrMat, ::Val{:X}, locs::NTuple{N, Int}) where N
    mask = bmask(locs)
    do_mask = bmask(first(locs))
    @simd for b in basis(state)
        local i_::Int
        @inbounds if testany(b, do_mask)
            i = b+1
            i_ = flip(b, mask) + 1
            swaprows!(state, i, i_)
        end
    end
    return state
end

function YaoBase.instruct!(state::AbstractVecOrMat{T}, ::Val{:Y}, locs::NTuple{N, Int}) where {T, N}
    mask = bmask(Int, locs); do_mask = bmask(Int, first(locs))
    bit_parity = iseven(length(bits)) ? 1 : -1
    factor = T(-im)^length(locs)

    @simd for b in basis(Int, state)
        local i::Int, i_::Int
        if anymasked(b, do_mask)
            i = b + 1
            i_ = flip(b, mask) + 1
            factor1 = isodd(count_ones(b & mask)) ? -factor : factor
            factor2 = factor1 * bit_parity
            swaprows!(state, i, i_, factor2, factor1)
        end
    end
    return state
end

function YaoBase.instruct!(state::AbstractVecOrMat{T}, ::Val{:Z}, locs::NTuple{N, Int}) where {T, N}
    mask = bmask(Int, locs)
    for b in basis(Int, state)
        if isodd(count_ones(b & mask))
            mulrow!(state, b + 1, -1)
        end
    end
    return state
end

for (G, FACTOR) in zip([:S, :T, :Sdag, :Tdag], [:(im), :($(exp(im*π/4))), :(-im), :($(exp(-im*π/4)))])
    @eval function YaoBase.instruct!(state::AbstractVecOrMat{T}, ::Val{$(QuoteNode(G))}, locs::NTuple{N, Int}) where {T, N}
        mask = bmask(Int, locs)
        for b in basis(Int, state)
            mulrow!(state, b+1, $FACTOR^count_ones(b & mask))
        end
        return state
    end
end

for (G, FACTOR) in zip([:Z, :S, :T, :Sdag, :Tdag], [:(-1), :(im), :($(exp(im*π/4))), :(-im), :($(exp(-im*π/4)))])
    # forward single gate
    @eval YaoBase.instruct!(state::AbstractVecOrMat, g::Val{$(QuoteNode(G))}, locs::Tuple{Int}) =
        instruct!(state, g, locs...)

    @eval function YaoBase.instruct!(state::AbstractVecOrMat{T}, ::Val{$(QuoteNode(G))}, locs::Int) where T
        mask = bmask(locs)
        step = 1<<(locs-1)
        step_2 = 1<<locs
        for j in 0:step_2:size(state, 1)-step
            for i in j+step+1:j+step_2
                mulrow!(state, i, $FACTOR)
            end
        end
        state
    end
end

# multi-controlled gates
## controlled paulis
function YaoBase.instruct!(
    state::AbstractVecOrMat{T}, ::Val{:X},
    locs::NTuple{N1, Int},
    control_bits::NTuple{N2, Int},
    control_vals::NTuple{N3, Int}) where {T, N1, N2, N3}

    ctrl = controller((control_bits..., locs[1]), (control_vals..., 0))
    mask2 = bmask(locs)
    @simd for b in basis(state)
        local i_::Int
        if ctrl(b)
            i = b + 1
            i_ = flip(b, mask2) + 1
            swaprows!(state, i, i_)
        end
    end
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T}, ::Val{:Y},
    locs::NTuple{N1, Int},
    control_bits::NTuple{N2, Int},
    control_vals::NTuple{N3, Int}) where {T, N1,N2,N3}

    ctrl = controller((control_bits..., locs[1]), (control_vals..., 0))
    mask2 = bmask(locs)
    @simd for b in basis(state)
        local i_::Int
        if ctrl(b)
            i = b + 1
            i_ = flip(b, mask2) + 1
            swaprows!(state, i, i_, im, -im)
        end
    end
    return state
end

for (G, FACTOR) in zip([:Z, :S, :T, :Sdag, :Tdag], [:(-1), :(im), :($(exp(im*π/4))), :(-im), :($(exp(-im*π/4)))])
    @eval function YaoBase.instruct!(
            state::AbstractVecOrMat{T}, ::Val{$(QuoteNode(G))},
            locs::NTuple{N1, Int},
            control_bits::NTuple{N2, Int},
            control_vals::NTuple{N3, Int}) where {T, N1, N2, N3}

        ctrl = controller([cbits..., b2[1]], [cvals..., 1])
        for b in basis(state)
            if ctrl(b)
                mulrow!(state, b+1, $FACTOR)
            end
        end
        return state
    end
end

## single controlled paulis
for G in [:X, :Y, :Z, :S, :T, :Sdag, :Tdag]
    # forward single controlled
    @eval YaoBase.instruct!(state::AbstractVecOrMat, ::Val{$(QuoteNode(G))},
        locs::NTuple{N, Int}, control_bits::Tuple{Int}, control_vals::Tuple{Int}) where N =
            instruct!(state, g, locs, control_bits..., control_vals...)
end


function YaoBase.instruct!(
        state::AbstractVecOrMat{T},
        ::Val{:X}, loc::Int,
        control_bits::Int, control_vals::Int) where T

    mask2 = bmask(loc); mask = bmask(control_bits, loc)
    step = 1 << (control_bits-1)
    step_2 = 1 << control_bits
    start = control_vals == 1 ? step : 0
    for j in start:step_2:size(state, 1)-step+start
        local i_::Int
        @simd for b in j:j+step-1
            @inbounds if allmasked(b, mask2)
                i = b+1
                i_ = flip(b, mask2) + 1
                swaprows!(state, i, i_)
            end
        end
    end
    return state
end

function YaoBase.instruct!(
        state::AbstractVecOrMat{T},
        ::Val{:Y}, loc::Int,
        control_bits::Int, control_vals::Int) where T

    mask2 = bmask(loc); mask = bmask(control_bits, loc)
    step = 1<<(control_bits-1)
    step_2 = 1<<control_bits
    start = control_vals==1 ? step : 0
    for j in start:step_2:size(state, 1)-step+start
        local i_::Int
        @simd for b in j:j+step-1
            @inbounds if allmasked(b, mask2)
                i = b+1
                i_ = flip(b, mask2) + 1
                if allmasked(b, mask2)
                    factor = T(im)
                else
                    factor = T(-im)
                end
                swaprows!(state, i, i_, -factor, factor)
            end
        end
    end
    return state
end


for (G, FACTOR) in zip([:Z, :S, :T, :Sdag, :Tdag], [:(-1), :(im), :($(exp(im*π/4))), :(-im), :($(exp(-im*π/4)))])
    @eval function YaoBase.instruct!(
            state::AbstractVecOrMat{T},
            ::Val{$(QuoteNode(G))}, loc::Int,
            control_bits::Int,
            control_vals::Int) where T

        mask2 = bmask(loc)
        step = 1 << (control_bits - 1)
        step_2 = 1 << control_bits
        start = control_vals == 1 ? step : 0
        for j in start:step_2:size(state, 1)-step+start
            for i in j+1:j+step
                if allmasked(i-1, mask2)
                    mulrow!(state, i, $FACTOR)
                end
            end
        end
        return state
    end
end
