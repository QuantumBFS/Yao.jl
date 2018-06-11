function xapply!(state::VecOrMat{T}, bits::Ints) where T
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
            swaprows(state, i, i_)
        end
    end
    state
end

function yapply!(state::VecOrMat{T}, bits::Ints) where T
    if length(bits) == 0
        return state
    end
    mask = bmask(bits...)
    do_mask = bmask(bits[1])
    bit_parity = length(bits)%2 == 0 ? 1 : -1
    factor = T(-im)^length(bits)

    @simd for b = basis(state)
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
            swaprows(state, i, i_, factor2, factor1)
        end
    end
    state
end

function zapply!(state::VecOrMat{T}, bits::Ints) where T
    mask = bmask(bits...)
    for b in basis(state)
        if count_ones(b&mask)%2==1
            mulrow(state, b+1, -1)
        end
    end
    state
end

function zapply!(state::VecOrMat{T}, bit::Int) where T
    mask = bmask(bit)
    @simd for b in basis(state)
        if testany(b, mask)
            mulrow(state, b+1, -1)
        end
    end
    state
end

function cxapply!(state::VecOrMat{T}, b1::Ints, b2::Ints) where T
    do_mask = bmask(b1..., b2[1])
    mask2 = bmask(b2...)

    @simd for b = basis(state)
        local temp::T
        local i_::Int
        if testall(b, do_mask)
            i = b+1
            i_ = flip(b, mask2) + 1
            swaprows(state, i, i_)
        end
    end
    state
end

function czapply!(state::VecOrMat{T}, b1::Ints, b2::Ints) where T
    mask2 = bmask(b2)
    step = 1<<(b1-1)
    step_2 = 1<<b1
    for j = step:step_2:length(state)-1
        @simd for i = j+1:j+step
            if testall(i-1, mask2)
                @inbounds mulrow(state, i, -1)
            end
        end
    end
    state
end

function cyapply!(state::VecOrMat{T}, b1::Ints, b2::Ints) where T
    mask2 = bmask(b2)
    mask = bmask(b1, b2)

    step = 1<<(b1-1)
    step_2 = 1<<b1
    for j = step:step_2:length(state)-1
        local temp::T
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
                swaprows(state, i, i_, -factor, factor)
            end
        end
    end
    state
end
