# NOTE:
# in principal we only allow one to input a tuple of address to instruct
# but most of the instruct function in this file defines a forward method
# for single qubit version with an int as input.

using YaoBase, BitBasis, LuxurySparse, StaticArrays
export instruct!

function YaoBase.instruct!(reg::ArrayReg, operator, args...; kwargs...)
    instruct!(matvec(reg.state), operator, args...; kwargs...)
end

"""
    SPECIALIZATION_LIST::Vector{Symbol}

A list of symbol for specialized gates/operators.
"""
const SPECIALIZATION_LIST = Symbol[:X, :Y, :Z, :S, :T, :Sdag, :Tdag]

function YaoBase.instruct!(
    state::AbstractVecOrMat{T1},
    operator::AbstractMatrix{T2},
    locs::Tuple{},
    control_locs::NTuple{C, Int}=(),
    control_bits::NTuple{C, Int}=()) where {T1, T2, M, C}
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T1},
    operator::AbstractMatrix{T2},
    locs::NTuple{M, Int},
    control_locs::NTuple{C, Int}=(),
    control_bits::NTuple{C, Int}=()) where {T1, T2, M, C}

    @warn "Element Type Mismatch: register $(T1), operator $(T2). Converting operator to match, this may cause performance issue"
    return instruct!(state, copyto!(similar(operator, T1), operator), locs, control_locs, control_bits)
end

function YaoBase.instruct!(state::AbstractVecOrMat{T1}, U1::AbstractMatrix{T2}, loc::Int) where {T1, T2}
    @warn "Element Type Mismatch: register $(T1), operator $(T2). Converting operator to match, this may cause performance issue"
    return instruct!(state, copyto!(similar(U1, T1), U1), loc)
end

function YaoBase.instruct!(state::AbstractVecOrMat{T1}, U1::SDPermMatrix{T2}, loc::Int) where {T1, T2}
    @warn "Element Type Mismatch: register $(T1), operator $(T2). Converting operator to match, this may cause performance issue"
    return instruct!(state, copyto!(similar(U1, T1), U1), loc)
end

function YaoBase.instruct!(state::AbstractVecOrMat{T1}, U1::SDDiagonal{T2}, loc::Int) where {T1, T2}
    @warn "Element Type Mismatch: register $(T1), operator $(T2). Converting operator to match, this may cause performance issue"
    return instruct!(state, copyto!(similar(U1, T1), U1), loc)
end

function _prepare_instruct(state, U, locs::NTuple{M}, control_locs, control_bits::NTuple{C}) where {M, C}
    N, MM = log2dim1(state), size(U, 1)

    locked_bits = MVector(control_locs..., locs...)
    locked_vals = MVector(control_bits..., (0 for k in 1:M)...)
    locs_raw_it = (b+1 for b in itercontrol(N, setdiff(1:N, locs), zeros(Int, N-M)))
    locs_raw = SVector(locs_raw_it...)
    ic = itercontrol(N, locked_bits, locked_vals)
    return locs_raw, ic
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    operator::AbstractMatrix{T},
    locs::Tuple{},
    control_locs::NTuple{C, Int} = (),
    control_bits::NTuple{C, Int} = ()) where {T, M, C}
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    operator::AbstractMatrix{T},
    locs::NTuple{M, Int},
    control_locs::NTuple{C, Int} = (),
    control_bits::NTuple{C, Int} = ()) where {T, M, C}

    U = sort_unitary(operator, locs)
    locs_raw, ic = _prepare_instruct(state, U, locs, control_locs, control_bits)

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
YaoBase.instruct!(state::AbstractVecOrMat, U::IMatrix, locs::Tuple{Int}) = state

# one-qubit instruction
YaoBase.instruct!(state::AbstractVecOrMat, g::AbstractMatrix, locs::Tuple{Int}) =
    instruct!(state, g, locs...)

function YaoBase.instruct!(state::AbstractVecOrMat{T}, U1::AbstractMatrix{T}, loc::Int) where T
    a, c, b, d = U1
    instruct_kernel(state, loc, 1<<(loc-1), 1<<loc, a, b, c, d)
    return state
end

@inline function instruct_kernel(state::AbstractVecOrMat, loc, step1, step2, a, b, c, d)
    for j in 0:step2:size(state, 1)-step1
        @inbounds for i in j+1:j+step1
            u1rows!(state, i, i+step1, a, b, c, d)
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
        @inbounds for i in j+1:j+step
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
        @inbounds for i in j+1:j+step
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
    for b in basis(state)
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

    for b in basis(Int, state)
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

    # no effect (to fix ambiguity)
    @eval YaoBase.instruct!(st::AbstractVecOrMat, ::Val{$(QuoteNode(G))}, ::Tuple{}) = st

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


# Specialized
import YaoBase: rot_mat

rot_mat(::Type{T}, ::Val{:Rx}, theta::Real) where T =
    T[cos(theta/2) -im * sin(theta/2); -im * sin(theta/2) cos(theta/2)]
rot_mat(::Type{T}, ::Val{:Ry}, theta::Real) where T =
    T[cos(theta/2) -sin(theta/2); sin(theta/2) cos(theta/2)]
rot_mat(::Type{T}, ::Val{:Rz}, theta::Real) where T =
    Diagonal(T[exp(-im*theta/2), exp(im*theta/2)])
rot_mat(::Type{T}, ::Val{:CPHASE}, theta::Real) where T =
    Diagonal(T[1, 1, 1, exp(im*theta)])
rot_mat(::Type{T}, ::Val{:PSWAP}, theta::Real) where T =
    rot_mat(T, Const.SWAP, theta)

for G in [:Rx, :Ry, :Rz, :CPHASE]
    # forward single gates
    @eval function YaoBase.instruct!(state::AbstractVecOrMat{T}, g::Val{$(QuoteNode(G))},
                            locs::Union{Int, NTuple{N3,Int}},
                            control_locs::NTuple{N1, Int},
                            control_bits::NTuple{N2, Int}, theta::Real) where {T, N1, N2, N3}
        m = rot_mat(T, g, theta)
        instruct!(state, m, locs, control_locs, control_bits)
    end
end

# forward single gates
@eval function YaoBase.instruct!(state::AbstractVecOrMat{T}, g::Val,
                        locs::Union{Int, NTuple{N1, Int}}, theta::Real) where {T, N1}
    instruct!(state, g, locs, (), (), theta)
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T}, ::Val{:X},
    locs::NTuple{N1, Int},
    control_locs::NTuple{N2, Int},
    control_bits::NTuple{N3, Int}) where {T, N1, N2, N3}

    ctrl = controller((control_locs..., locs[1]), (control_bits..., 0))
    mask2 = bmask(locs)
    for b in basis(state)
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
    for b in basis(state)
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
        for b in j:j+step-1
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
        for b in j:j+step-1
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
    for b in basis(state)
        if b&mask1==0 && b&mask2==mask2
            i = b+1
            i_ = b ⊻ mask12 + 1
            swaprows!(state, i, i_)
        end
    end
    return state
end

function YaoBase.instruct!(
        state::AbstractVecOrMat{T},
        ::Val{:PSWAP},
        locs::Tuple{Int, Int},
        theta::Real) where T
    mask1 = bmask(locs[1])
    mask2 = bmask(locs[2])
    mask12 = mask1|mask2
    a = T(cos(theta/2))
    c = T(-im * sin(theta/2))
    e = T(exp(-im/2*theta))
    for b in basis(state)
        if b&mask1==0
            i = b+1
            i_ = b ⊻ mask12 + 1
            if b&mask2==mask2
                u1rows!(state, i, i_, a, c, c, a)
            else
                mulrow!(state, i, e)
                mulrow!(state, i_, e)
            end
        end
    end
    return state
end

function YaoBase.instruct!(
        state::AbstractVecOrMat{T},
        ::Val{:PSWAP},
        locs::Tuple{Int, Int},
        control_locs::NTuple{C, Int},
        control_bits::NTuple{C, Int},
        theta::Real) where {T, C}
    mask1 = bmask(locs[1])
    mask2 = bmask(locs[2])
    mask12 = mask1|mask2
    a = T(cos(theta/2))
    c = T(-im * sin(theta/2))
    e = T(exp(-im/2*theta))
    for b in itercontrol(log2i(size(state, 1)), [control_locs...], [control_bits...])
        if b&mask1==0
            i = b+1
            i_ = b ⊻ mask12 + 1
            if b&mask2==mask2
                u1rows!(state, i, i_, a, c, c, a)
            else
                mulrow!(state, i, e)
                mulrow!(state, i_, e)
            end
        end
    end
    return state
end
