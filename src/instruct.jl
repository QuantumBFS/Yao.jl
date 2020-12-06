# NOTE:
# in principal we only allow one to input a tuple of address to instruct
# but most of the instruct function in this file defines a forward method
# for single qubit version with an int as input.
#
#
# In order to make multi threading work, the state vector MUST be named as state

using YaoBase, BitBasis, LuxurySparse, StaticArrays
export instruct!

function YaoBase.instruct!(
    r::ArrayReg,
    op,
    locs::Tuple,
    control_locs::Tuple,
    control_bits::Tuple,
)
    instruct!(r.state, op, locs, control_locs, control_bits)
end

function YaoBase.instruct!(r::ArrayReg, op, locs::Tuple)
    instruct!(r.state, op, locs)
end

function YaoBase.instruct!(
    r::ArrayReg,
    op,
    locs::Tuple,
    control_locs::Tuple,
    control_bits::Tuple,
    theta::Number,
)
    instruct!(r.state, op, locs, control_locs, control_bits, theta)
end

function YaoBase.instruct!(r::ArrayReg, op, locs::Tuple, theta::Number)
    instruct!(r.state, op, locs, theta)
end

"""
    SPECIALIZATION_LIST::Vector{Symbol}

A list of symbol for specialized gates/operators.
"""
const SPECIALIZATION_LIST =
    Symbol[:X, :Y, :Z, :S, :T, :Sdag, :Tdag, :H, :SWAP, :PSWAP, :CPHASE]


const THREAD_THRESHOLD = 10

# generates the threading expression
macro threads(ex)
    esc(quote
        if (Threads.nthreads() == 1) || log2dim1(state) < $THREAD_THRESHOLD
            @inbounds $ex
        else
            @inbounds Threads.@threads $ex
        end
    end)
end

# to avoid potential ambiguity, we limit them to tuple for now
# but they only has to be an iterator over integers
const Locations{T} = NTuple{N,T} where {N}
const BitConfigs{T} = NTuple{N,T} where {N}

function YaoBase.instruct!(
    state::AbstractVecOrMat{T1},
    operator::AbstractMatrix{T2},
    locs::Tuple{},
    control_locs::NTuple{C,Int} = (),
    control_bits::NTuple{C,Int} = (),
) where {T1,T2,M,C}
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T1},
    operator::AbstractMatrix{T2},
    locs::NTuple{M,Int},
    control_locs::NTuple{C,Int} = (),
    control_bits::NTuple{C,Int} = (),
) where {T1,T2,M,C}

    @warn "Element Type Mismatch: register $(T1), operator $(T2). Converting operator to match, this may cause performance issue"
    return instruct!(
        state,
        copyto!(similar(operator, T1), operator),
        locs,
        control_locs,
        control_bits,
    )
end

function _prepare_instruct(
    state,
    U,
    locs::NTuple{M},
    control_locs,
    control_bits::NTuple{C},
) where {M,C}
    N, MM = log2dim1(state), size(U, 1)

    locked_bits = MVector(control_locs..., locs...)
    locked_vals = MVector(control_bits..., (0 for k = 1:M)...)
    locs_raw_it = (b + 1 for b in itercontrol(N, setdiff(1:N, locs), zeros(Int, N - M)))
    locs_raw = SVector(locs_raw_it...)
    ic = itercontrol(N, locked_bits, locked_vals)
    return locs_raw, ic
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    operator::AbstractMatrix{T},
    locs::Tuple{},
    control_locs::NTuple{C,Int} = (),
    control_bits::NTuple{C,Int} = (),
) where {T,M,C}
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    operator::AbstractMatrix{T},
    locs::NTuple{M,Int},
    control_locs::NTuple{C,Int} = (),
    control_bits::NTuple{C,Int} = (),
) where {T,M,C}
    operator = sort_unitary(operator, locs)
    locs_raw, ic = _prepare_instruct(state, operator, locs, control_locs, control_bits)
    return _instruct!(state, autostatic(operator), locs_raw, ic)
end

function _instruct!(
    state::AbstractVecOrMat{T},
    U::AbstractMatrix{T},
    locs_raw::SVector,
    ic::IterControl,
) where {T}
    @threads for j = 1:length(ic)
        @inbounds i = ic[j]
        @inbounds unrows!(state, locs_raw .+ i, U)
    end
    return state
end

function _instruct!(
    state::AbstractVecOrMat{T},
    U::SDSparseMatrixCSC{T},
    locs_raw::SVector,
    ic::IterControl,
) where {T}
    work =
        ndims(state) == 1 ? similar(state, length(locs_raw)) :
        similar(state, length(locs_raw), size(state, 2))
    @threads for j = 1:length(ic)
        @inbounds i = ic[j]
        @inbounds unrows!(state, locs_raw .+ i, U, work)
    end
    return state
end

YaoBase.instruct!(state::AbstractVecOrMat, U::IMatrix, locs::NTuple{N,Int}) where {N} =
    state
YaoBase.instruct!(state::AbstractVecOrMat, U::IMatrix, locs::Tuple{Int}) = state

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    U1::AbstractMatrix{T},
    (loc,)::Tuple{Int},
) where {T}
    a, c, b, d = U1
    instruct_kernel(state, loc, 1 << (loc - 1), 1 << loc, a, b, c, d)
    return state
end

@inline function instruct_kernel(state::AbstractVecOrMat, loc, step1, step2, a, b, c, d)
    @threads for j = 0:step2:size(state, 1)-step1
        @inbounds for i = j+1:j+step1
            u1rows!(state, i, i + step1, a, b, c, d)
        end
    end
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    U1::SDPermMatrix{T},
    (loc,)::Tuple{Int},
) where {T}
    U1.perm[1] == 1 && return instruct!(state, Diagonal(U1), (loc,))
    mask = bmask(loc)
    b, c = U1.vals
    step = 1 << (loc - 1)
    step_2 = 1 << loc

    @threads for j = 0:step_2:size(state, 1)-step
        @inbounds for i = j+1:j+step
            swaprows!(state, i, i + step, c, b)
        end
    end
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    U1::SDDiagonal{T},
    (loc,)::Tuple{Int},
) where {T}
    mask = bmask(loc)
    a, d = U1.diag
    step = 1 << (loc - 1)
    step_2 = 1 << loc
    @threads for j = 0:step_2:size(state, 1)-step
        @inbounds for i = j+1:j+step
            mulrow!(state, i, a)
            mulrow!(state, i + step, d)
        end
    end
    return state
end

# specialization
# paulis
function YaoBase.instruct!(
    state::AbstractVecOrMat,
    ::Val{:X},
    locs::NTuple{N,Int},
) where {N}
    mask = bmask(locs)
    do_mask = bmask(first(locs))
    @threads for b in basis(state)
        @inbounds if anyone(b, do_mask)
            i = b + 1
            i_ = flip(b, mask) + 1
            swaprows!(state, i, i_)
        end
    end
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat,
    ::Val{:H},
    locs::NTuple{N,Int},
) where {N}
    instruct!(state, YaoBase.Const.H, locs)
end


function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    ::Val{:Y},
    locs::NTuple{N,Int},
) where {T,N}
    mask = bmask(Int, locs)
    do_mask = bmask(Int, first(locs))
    bit_parity = iseven(length(locs)) ? 1 : -1
    factor = T(-im)^length(locs)

    @threads for b in basis(Int, state)
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

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    ::Val{:Z},
    locs::NTuple{N,Int},
) where {T,N}
    mask = bmask(Int, locs)
    @threads for b in basis(Int, state)
        if isodd(count_ones(b & mask))
            mulrow!(state, b + 1, -1)
        end
    end
    return state
end

for (G, FACTOR) in zip(
    [:S, :T, :Sdag, :Tdag],
    [:(im), :($(exp(im * π / 4))), :(-im), :($(exp(-im * π / 4)))],
)
    @eval function YaoBase.instruct!(
        state::AbstractVecOrMat{T},
        ::Val{$(QuoteNode(G))},
        locs::NTuple{N,Int},
    ) where {T,N}
        mask = bmask(Int, locs)
        @threads for b in basis(Int, state)
            mulrow!(state, b + 1, $FACTOR^count_ones(b & mask))
        end
        return state
    end
end

for (G, FACTOR) in zip(
    [:Z, :S, :T, :Sdag, :Tdag],
    [:(-1), :(im), :($(exp(im * π / 4))), :(-im), :($(exp(-im * π / 4)))],
)
    # no effect (to fix ambiguity)
    @eval YaoBase.instruct!(st::AbstractVecOrMat, ::Val{$(QuoteNode(G))}, ::Tuple{}) = st

    @eval function YaoBase.instruct!(
        state::AbstractVecOrMat{T},
        ::Val{$(QuoteNode(G))},
        (loc,)::Tuple{Int},
    ) where {T}
        mask = bmask(loc)
        step = 1 << (loc - 1)
        step_2 = 1 << loc
        @threads for j = 0:step_2:size(state, 1)-step
            for i = j+step+1:j+step_2
                mulrow!(state, i, $FACTOR)
            end
        end
        state
    end
end

# Specialized
import YaoBase: rot_mat

rot_mat(::Type{T}, ::Val{:Rx}, theta::Number) where {T} =
    T[cos(theta / 2) -im*sin(theta / 2); -im*sin(theta / 2) cos(theta / 2)]
rot_mat(::Type{T}, ::Val{:Ry}, theta::Number) where {T} =
    T[cos(theta / 2) -sin(theta / 2); sin(theta / 2) cos(theta / 2)]
rot_mat(::Type{T}, ::Val{:Rz}, theta::Number) where {T} =
    Diagonal(T[exp(-im * theta / 2), exp(im * theta / 2)])
rot_mat(::Type{T}, ::Val{:CPHASE}, theta::Number) where {T} =
    Diagonal(T[1, 1, 1, exp(im * theta)])
rot_mat(::Type{T}, ::Val{:PSWAP}, theta::Number) where {T} = rot_mat(T, Const.SWAP, theta)

for G in [:Rx, :Ry, :Rz, :CPHASE]
    # forward single gates
    @eval function YaoBase.instruct!(
        state::AbstractVecOrMat{T},
        g::Val{$(QuoteNode(G))},
        locs::NTuple{N3,Int},
        control_locs::NTuple{N1,Int},
        control_bits::NTuple{N2,Int},
        theta::Number,
    ) where {T,N1,N2,N3}
        m = rot_mat(T, g, theta)
        instruct!(state, m, locs, control_locs, control_bits)
        return state
    end
end # for

@inline function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    ::Val{:Rx},
    (loc,)::Tuple{Int},
    theta::Number,
) where {T,N}
    b, a = sincos(theta / 2)
    instruct_kernel(state, loc, 1 << (loc - 1), 1 << loc, a, -im * b, -im * b, a)
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    ::Val{:Ry},
    (loc,)::Tuple{Int},
    theta::Number,
) where {T,N}
    b, a = sincos(theta / 2)
    instruct_kernel(state, loc, 1 << (loc - 1), 1 << loc, a, -b, b, a)
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    ::Val{:Rz},
    (loc,)::Tuple{Int},
    theta::Number,
) where {T,N}
    a = exp(-im * theta / 2)
    instruct_kernel(state, loc, 1 << (loc - 1), 1 << loc, a, zero(T), zero(T), a')
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    ::Val{:CPHASE},
    locs::NTuple{N,Int},
    theta::Number,
) where {T,N}
    m = rot_mat(T, Val(:CPHASE), theta)
    instruct!(state, m, locs)
    return state
end


# forward single gates
function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    g::Val,
    locs::Union{Int,NTuple{N1,Int}},
    theta::Number,
) where {T,N1}
    instruct!(state, g, locs, (), (), theta)
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    ::Val{:X},
    locs::NTuple{N1,Int},
    control_locs::NTuple{N2,Int},
    control_bits::NTuple{N3,Int},
) where {T,N1,N2,N3}

    ctrl = controller((control_locs..., locs[1]), (control_bits..., 0))
    mask2 = bmask(locs)
    @threads for b in basis(state)
        if ctrl(b)
            i = b + 1
            i_ = flip(b, mask2) + 1
            swaprows!(state, i, i_)
        end
    end
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    ::Val{:Y},
    locs::NTuple{N1,Int},
    control_locs::NTuple{N2,Int},
    control_bits::NTuple{N3,Int},
) where {T,N1,N2,N3}

    ctrl = controller((control_locs..., locs[1]), (control_bits..., 0))
    mask2 = bmask(locs)
    @threads for b in basis(state)
        if ctrl(b)
            i = b + 1
            i_ = flip(b, mask2) + 1
            swaprows!(state, i, i_, im, -im)
        end
    end
    return state
end

for (G, FACTOR) in zip(
    [:Z, :S, :T, :Sdag, :Tdag],
    [:(-1), :(im), :($(exp(im * π / 4))), :(-im), :($(exp(-im * π / 4)))],
)
    @eval function YaoBase.instruct!(
        state::AbstractVecOrMat{T},
        ::Val{$(QuoteNode(G))},
        locs::NTuple{N1,Int},
        control_locs::NTuple{N2,Int},
        control_bits::NTuple{N3,Int},
    ) where {T,N1,N2,N3}

        ctrl = controller([control_locs..., locs[1]], [control_bits..., 1])
        @threads for b in basis(state)
            if ctrl(b)
                mulrow!(state, b + 1, $FACTOR)
            end
        end
        return state
    end
end

## single controlled paulis
for G in [:X, :Y, :Z, :S, :T, :Sdag, :Tdag]
    # forward single controlled
    @eval YaoBase.instruct!(
        state::AbstractVecOrMat,
        g::Val{$(QuoteNode(G))},
        locs::NTuple{N,Int},
        control_locs::Tuple{Int},
        control_bits::Tuple{Int},
    ) where {N} = instruct!(state, g, locs, control_locs..., control_bits...)

    # forward single location
    @eval YaoBase.instruct!(
        state::AbstractVecOrMat,
        g::Val{$(QuoteNode(G))},
        locs::Tuple{Int},
        control_locs::Int,
        control_bits::Int,
    ) where {N} = instruct!(state, g, locs..., control_locs, control_bits)

end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    ::Val{:X},
    loc::Int,
    control_locs::Int,
    control_bits::Int,
) where {T}

    mask2 = bmask(loc)
    mask = bmask(control_locs, loc)
    step = 1 << (control_locs - 1)
    step_2 = 1 << control_locs
    start = control_bits == 1 ? step : 0
    @threads for j = start:step_2:size(state, 1)-step+start
        for b = j:j+step-1
            @inbounds if allone(b, mask2)
                i = b + 1
                i_ = flip(b, mask2) + 1
                swaprows!(state, i, i_)
            end
        end
    end
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    ::Val{:Y},
    loc::Int,
    control_locs::Int,
    control_bits::Int,
) where {T}

    mask2 = bmask(loc)
    mask = bmask(control_locs, loc)
    step = 1 << (control_locs - 1)
    step_2 = 1 << control_locs
    start = control_bits == 1 ? step : 0
    @threads for j = start:step_2:size(state, 1)-step+start
        for b = j:j+step-1
            @inbounds if allone(b, mask2)
                i = b + 1
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


for (G, FACTOR) in zip(
    [:Z, :S, :T, :Sdag, :Tdag],
    [:(-1), :(im), :($(exp(im * π / 4))), :(-im), :($(exp(-im * π / 4)))],
)
    @eval function YaoBase.instruct!(
        state::AbstractVecOrMat{T},
        ::Val{$(QuoteNode(G))},
        loc::Int,
        control_locs::Int,
        control_bits::Int,
    ) where {T}

        mask2 = bmask(loc)
        step = 1 << (control_locs - 1)
        step_2 = 1 << control_locs
        start = control_bits == 1 ? step : 0
        @threads for j = start:step_2:size(state, 1)-step+start
            for i = j+1:j+step
                if allone(i - 1, mask2)
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
    locs::Tuple{Int,Int},
) where {T}

    mask1 = bmask(locs[1])
    mask2 = bmask(locs[2])
    mask12 = mask1 | mask2
    @threads for b in basis(state)
        if b & mask1 == 0 && b & mask2 == mask2
            i = b + 1
            i_ = b ⊻ mask12 + 1
            swaprows!(state, i, i_)
        end
    end
    return state
end

function YaoBase.instruct!(
    state::AbstractVecOrMat{T},
    ::Val{:PSWAP},
    locs::Tuple{Int,Int},
    theta::Number,
) where {T}
    mask1 = bmask(locs[1])
    mask2 = bmask(locs[2])
    mask12 = mask1 | mask2
    a = T(cos(theta / 2))
    c = T(-im * sin(theta / 2))
    e = T(exp(-im / 2 * theta))
    @threads for b in basis(state)
        if b & mask1 == 0
            i = b + 1
            i_ = b ⊻ mask12 + 1
            if b & mask2 == mask2
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
    locs::Tuple{Int,Int},
    control_locs::NTuple{C,Int},
    control_bits::NTuple{C,Int},
    theta::Number,
) where {T,C}
    mask1 = bmask(locs[1])
    mask2 = bmask(locs[2])
    mask12 = mask1 | mask2
    a = T(cos(theta / 2))
    c = T(-im * sin(theta / 2))
    e = T(exp(-im / 2 * theta))
    @threads for b in itercontrol(
        log2i(size(state, 1)),
        collect(Int, control_locs),
        collect(Int, control_bits),
    )
        if b & mask1 == 0
            i = b + 1
            i_ = b ⊻ mask12 + 1
            if b & mask2 == mask2
                u1rows!(state, i, i_, a, c, c, a)
            else
                mulrow!(state, i, e)
                mulrow!(state, i_, e)
            end
        end
    end
    return state
end
