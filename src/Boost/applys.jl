function xapply!(state::AbstractVecOrMat{T}, bits::Ints) where T
    if length(bits) == 0
        return state
    end
    mask = bmask(bits...)
    do_mask = bmask(bits[1])
    @simd for b = basis(state)
        local temp::T
        local i_::Int
        @inbounds if testany(b, do_mask)
            i = b+1
            i_ = flip(b, mask) + 1
            swaprows!(state, i, i_)
        end
    end
    state
end

function yapply!(state::AbstractVecOrMat{T}, bits::Ints{Int}) where T
    if length(bits) == 0
        return state
    end
    mask = bmask(Int, bits...)
    do_mask = bmask(Int, bits[1])
    bit_parity = length(bits)%2 == 0 ? 1 : -1
    factor = T(-im)^length(bits)

    @simd for b = basis(Int, state)
        local temp::T
        local factor1::T
        local factor2::T
        local i_::Int
        local i::Int
        if testany(b, do_mask)
            i = b+1
            i_ = flip(b, mask) + 1
            factor1 = count_ones(b&mask)%2 == 1 ? -factor : factor
            factor2 = factor1*bit_parity
            swaprows!(state, i, i_, factor2, factor1)
        end
    end
    state
end

function zapply!(state::AbstractVecOrMat{T}, bits::Ints{Int}) where T
    mask = bmask(Int, bits...)
    for b in basis(Int, state)
        if count_ones(b&mask)%2==1
            mulrow!(state, b+1, -1)
        end
    end
    state
end

function zapply!(state::AbstractVecOrMat{T}, bit::Int) where T
    mask = bmask(bit)
    @simd for b in basis(state)
        if testany(b, mask)
            mulrow!(state, b+1, -1)
        end
    end
    state
end

################### Multi Controlled Version ####################

function czapply!(state::AbstractVecOrMat{T}, cbits, cvals, b2::Int) where T
    c = controller([cbits..., b2[1]], [cvals..., 1])
    @simd for b = basis(state)
        if b |> c
            mulrow!(state, b+1, -1)
        end
    end
    state
end

function cyapply!(state::AbstractVecOrMat{T}, cbits, cvals, b2::Int) where T
    c = controller([cbits..., b2[1]], [cvals..., 0])
    mask2 = bmask(b2...)
    @simd for b = basis(state)
        local i_::Int
        if b |> c
            i = b+1
            i_ = flip(b, mask2) + 1
            swaprows!(state, i, i_, im, -im)
        end
    end
    state
end


function cxapply!(state::AbstractVecOrMat{T}, cbits, cvals, b2) where T
    c = controller([cbits..., b2[1]], [cvals..., 0])
    mask2 = bmask(b2...)

    @simd for b = basis(state)
        local i_::Int
        if b |> c
            i = b+1
            i_ = flip(b, mask2) + 1
            swaprows!(state, i, i_)
        end
    end
    state
end

################### Single Controlled Version ####################

function czapply!(state::AbstractVecOrMat{T}, cbit::Int, cval::Int, b2::Int) where T
    mask2 = bmask(b2)
    step = 1<<(cbit-1)
    step_2 = 1<<cbit
    start = cval==1 ? step : 0
    for j = start:step_2:size(state, 1)-step+start
        @simd for i = j+1:j+step
            if testall(i-1, mask2)
                mulrow!(state, i, -1)
            end
        end
    end
    state
end

function cyapply!(state::AbstractVecOrMat{T}, cbit::Int, cval::Int, b2::Int) where T
    mask2 = bmask(b2)
    mask = bmask(cbit, b2)

    step = 1<<(cbit-1)
    step_2 = 1<<cbit
    start = cval==1 ? step : 0
    for j = start:step_2:size(state, 1)-step+start
        local i_::Int
        @simd for b = j:j+step-1
            @inbounds if testall(b, mask2)
                i = b+1
                i_ = flip(b, mask2) + 1
                if testall(b, mask2)
                    factor = T(im)
                else
                    factor = T(-im)
                end
                swaprows!(state, i, i_, -factor, factor)
            end
        end
    end
    state
end

function cxapply!(state::AbstractVecOrMat{T}, cbit::Int, cval::Int, b2::Int) where T
    mask2 = bmask(b2)
    mask = bmask(cbit, b2)

    step = 1<<(cbit-1)
    step_2 = 1<<cbit
    start = cval==1 ? step : 0
    for j = start:step_2:size(state, 1)-step+start
        local i_::Int
        @simd for b = j:j+step-1
            @inbounds if testall(b, mask2)
                i = b+1
                i_ = flip(b, mask2) + 1
                swaprows!(state, i, i_)
            end
        end
    end
    state
end


####################### General Apply U1 ########################
function u1apply!(state::AbstractVecOrMat{T}, U1::PermMatrix{T}, ibit::Int) where T
    if U1.perm[1] == 1
        return u1apply!(state, Diagonal(U1), ibit)
    end
    mask = bmask(ibit)
    b, c = U1.vals
    step = 1<<(ibit-1)
    step_2 = 1<<ibit
    for j = 0:step_2:size(state, 1)-step
        @inbounds @simd for i = j+1:j+step
            swaprows!(state, i, i+step, c, b)
        end
    end
    state
end

function u1apply!(state::AbstractVecOrMat{T}, U1::Diagonal{T}, ibit::Int) where T
    mask = bmask(ibit)
    a, d = U1.diag
    step = 1<<(ibit-1)
    step_2 = 1<<ibit
    for j = 0:step_2:size(state, 1)-step
        @inbounds @simd for i = j+1:j+step
            mulrow!(state, i, a)
            mulrow!(state, i+step, d)
        end
    end
    state
end

u1apply!(state::AbstractVecOrMat, U1::IMatrix, ibit::Int) = state
