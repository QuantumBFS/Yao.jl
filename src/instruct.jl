# NOTE:
# in principal we only allow one to input a tuple of address to instruct
# but most of the instruct function in this file defines a forward method
# for single qubit version with an int as input.

using YaoBase, BitBasis, LuxurySparse, StaticArrays
export instruct!

# to avoid potential ambiguity, we limit them to tuple for now
# but they only has to be an iterator over integers
const Locations{T} = NTuple{N, T} where N
const BitConfigs{T} = NTuple{N, T} where N

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    operator::AbstractMatrix{T},
    locs::NTuple{M, Int},
    control_locs::NTuple{C, Int} = (),
    control_bits::NTuple{C, Int} = ()) where {T, M, C}

    U = sort_unitary(operator, locs)
    N, MM = log2dim1(state), size(U, 1)

    locked_bits = MVector(control_locs..., locs...)
    locked_vals = MVector(control_bits..., (0 for k in 1:M)...)
    locs_raw_it = (b+1 for b in itercontrol(N, setdiff(1:N, locs), zeros(Int, N-M)))
    locs_raw = SVector(locs_raw_it...)
    ic = itercontrol(N, locked_bits, locked_vals)

    return _instruct!(state, autostatic(U), locs_raw, ic)
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
YaoBase.instruct!(state::AbstractVecOrMat, U::IMatrix, locs::Int)  = state

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
        @inbounds if anyone(b, do_mask)
            i = b+1
            i_ = flip(b, mask) + 1
            swaprows!(state, i, i_)
        end
    end
    return state
end

function YaoBase.instruct!(state::AbstractVecOrMat{T}, ::Val{:Y}, locs::NTuple{N, Int}) where {T, N}
    mask = bmask(Int, locs); do_mask = bmask(Int, first(locs))
    bit_parity = iseven(length(locs)) ? 1 : -1
    factor = T(-im)^length(locs)

    @simd for b in basis(Int, state)
        local i::Int, i_::Int
        if anyone(b, do_mask)
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
for G in [:X, :Y, :Z, :S, :T, :Sdag, :Tdag]
    # forward single gates
    @eval YaoBase.instruct!(state::AbstractVecOrMat, g::Val{$(QuoteNode(G))},
                            locs::Int,
                            control_locs::NTuple{N1, Int},
                            control_bits::NTuple{N2, Int}) where {N1, N2} =
                instruct!(state, g, (locs, ), control_locs, control_bits)
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T}, ::Val{:X},
    locs::NTuple{N1, Int},
    control_locs::NTuple{N2, Int},
    control_bits::NTuple{N3, Int}) where {T, N1, N2, N3}

    ctrl = controller((control_locs..., locs[1]), (control_bits..., 0))
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
    control_locs::NTuple{N2, Int},
    control_bits::NTuple{N3, Int}) where {T, N1,N2,N3}

    ctrl = controller((control_locs..., locs[1]), (control_bits..., 0))
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
            control_locs::NTuple{N2, Int},
            control_bits::NTuple{N3, Int}) where {T, N1, N2, N3}

        ctrl = controller([control_locs..., locs[1]], [control_bits..., 1])
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
    @eval YaoBase.instruct!(state::AbstractVecOrMat, g::Val{$(QuoteNode(G))},
        locs::NTuple{N, Int}, control_locs::Tuple{Int}, control_bits::Tuple{Int}) where N =
            instruct!(state, g, locs, control_locs..., control_bits...)

    # forward single location
    @eval YaoBase.instruct!(state::AbstractVecOrMat, g::Val{$(QuoteNode(G))},
        locs::Tuple{Int}, control_locs::Int, control_bits::Int) where N =
            instruct!(state, g, locs..., control_locs, control_bits)

end

function YaoBase.instruct!(
        state::AbstractVecOrMat{T},
        ::Val{:X}, loc::Int,
        control_locs::Int, control_bits::Int) where T

    mask2 = bmask(loc); mask = bmask(control_locs, loc)
    step = 1 << (control_locs-1)
    step_2 = 1 << control_locs
    start = control_bits == 1 ? step : 0
    for j in start:step_2:size(state, 1)-step+start
        local i_::Int
        @simd for b in j:j+step-1
            @inbounds if allone(b, mask2)
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
        control_locs::Int, control_bits::Int) where T

    mask2 = bmask(loc); mask = bmask(control_locs, loc)
    step = 1<<(control_locs-1)
    step_2 = 1<<control_locs
    start = control_bits==1 ? step : 0
    for j in start:step_2:size(state, 1)-step+start
        local i_::Int
        @simd for b in j:j+step-1
            @inbounds if allone(b, mask2)
                i = b+1
                i_ = flip(b, mask2) + 1
                if allone(b, mask2)
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
            control_locs::Int,
            control_bits::Int) where T

        mask2 = bmask(loc)
        step = 1 << (control_locs - 1)
        step_2 = 1 << control_locs
        start = control_bits == 1 ? step : 0
        for j in start:step_2:size(state, 1)-step+start
            for i in j+1:j+step
                if allone(i-1, mask2)
                    mulrow!(state, i, $FACTOR)
                end
            end
        end
        return state
    end
end

# 2-qubit gates
function YaoBase.instruct!(
        state::AbstractVecOrMat{T},
        ::Val{:SWAP},
        locs::Tuple{Int, Int}) where T

    mask1 = bmask(locs[1])
    mask2 = bmask(locs[2])
    mask12 = mask1|mask2
    @simd for b = basis(state)
        local temp::T
        local i_::Int
        if b&mask1==0 && b&mask2==mask2
            i = b+1
            i_ = b ⊻ mask12 + 1
            swaprows!(state, i, i_)
        end
    end
    return state
end
