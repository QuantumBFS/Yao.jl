function xapply!(state::Matrix{T}, bits::Ints) where T
    if length(bits) == 0
        return state
    end
    mask = bmask(bits...)
    M, N = size(state)
    do_mask = bmask(bits[1])
    @simd for b = basis(state)
        local temp::T
        local i_::Int
        if testany(b, do_mask)
            i = b+1
            i_ = flip(b, mask) + 1
            @inbounds for c = 1:N
                temp = state[i, c]
                state[i, c] = state[i_, c]
                state[i_, c] = temp
            end
        end
    end
    state
end
function xapply!(state::Vector{T}, bits::Ints) where T
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
            temp = state[i]
            state[i] = state[i_]
            state[i_] = temp
        end
    end
    state
end

function yapply!(state::Vector{T}, bits::Ints) where T
    if length(bits) == 0
        return state
    end
    mask = bmask(bits...)
    do_mask = bmask(bits[1])
    factor = T(im^length(bits))

    @inbounds @simd for b = basis(state)
        local temp::T
        local i_::Int
        if testany(b, do_mask)
            i = b+1
            i_ = flip(b, mask) + 1
            temp = state[i]
            if count_ones(b&mask)%2 == 1
                state[i] = state[i_]*factor
                state[i_] = -temp*factor
            else
                state[i] = -state[i_]*factor
                state[i_] = temp*factor
            end
        end
    end
    state
end

function yapply!(state::Matrix{T}, bits::Ints) where T
    if length(bits) == 0
        return state
    end
    mask = bmask(bits...)
    do_mask = bmask(bits[1])
    factor = T(im^length(bits))
    M, N = size(state)

    @simd for b = basis(state)
        local temp::T
        local factor_::T
        local i_::Int
        if testany(b, do_mask)
            i = b+1
            i_ = flip(b, mask) + 1
            if count_ones(b&mask)%2 == 1
                factor_ = factor
            else
                factor_ = -factor
            end
            @simd for c = 1:N
                temp = state[i, c]
                @inbounds state[i, c] = state[i_, c]*factor_
                @inbounds state[i_, c] = -temp*factor_
            end
        end
    end
    state
end

function zapply!(state::Vector{T}, bits::Ints) where T
    mask = bmask(bits...)
    @simd for b in basis(state)
        if count_ones(b&mask)%2==1
            @inbounds state[b+1] *= -1
        end
    end
    state
end
function zapply!(state::Matrix{T}, bits::Ints) where T
    mask = bmask(bits...)
    M, N = size(state)
    for b in basis(state)
        if count_ones(b&mask)%2==1
            @simd for j = 1:N
                @inbounds state[b+1, j] *= -1
            end
        end
    end
    state
end

function zapply!(state::Vector{T}, bit::Int) where T
    mask = bmask(bit)
    @simd for b in basis(state)
        if testany(b, mask)
            @inbounds state[b+1] *= -1
        end
    end
    state
end
function zapply!(state::Matrix{T}, bit::Int) where T
    mask = bmask(bit)
    M, N = size(state)
    for b in basis(state)
        if testany(b, mask)
            @simd for j = 1:N
                @inbounds state[b+1, j] *= -1
            end
        end
    end
    state
end

function cxapply!(state::Matrix{T}, b1::Ints, b2::Ints) where T
    do_mask = bmask(b1..., b2[1])
    mask2 = bmask(b2...)
    M, N = size(state)
    
    @simd for b = basis(state)
        local temp::T
        local i_::Int
        if testall(b, do_mask)
            i = b+1
            i_ = flip(b, mask2) + 1
            @inbounds for c = 1:N
                temp = state[i, c]
                state[i, c] = state[i_, c]
                state[i_, c] = temp
            end
        end
    end
    state
end

function cxapply!(state::Vector{T}, b1::Ints, b2::Ints) where T
    do_mask = bmask(b1..., b2[1])
    mask2 = bmask(b2...)
    
    @simd for b = basis(state)
        local temp::T
        local i_::Int
        @inbounds if testall(b, do_mask)
            i = b+1
            i_ = flip(b, mask2) + 1
            temp = state[i]
            state[i] = state[i_]
            state[i_] = temp
        end
    end
    state
end

function czapply!(state::Vector{T}, b1::Ints, b2::Ints) where T
    mask2 = bmask(b2)
    step = 1<<(b1-1)
    step_2 = 1<<b1
    for j = step:step_2:length(state)-1
        @simd for i = j+1:j+step
            if testall(i-1, mask2)
                @inbounds state[i] *= -1
            end
        end
    end
    state
end

function czapply!(state::Matrix{T}, b1::Ints, b2::Ints) where T
    mask2 = bmask(b2)
    M, N = size(state)
    step = 1<<(b1-1)
    step_2 = 1<<b1
    for j = step:step_2:M-1
        @simd for i = j+1:j+step
            if testall(i-1, mask2)
                @simd for k = 1:N
                    @inbounds state[i, k] *= -1
                end
            end
        end
    end
    state
end

function cyapply!(state::Vector{T}, b1::Ints, b2::Ints) where T
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
                temp = state[i]
                state[i] = state[i_]*factor
                state[i_] = -temp*factor
            end
        end
    end
    state
end

function cyapply!(state::Matrix{T}, b1::Ints, b2::Ints) where T
    mask2 = bmask(b2)
    mask = bmask(b1, b2)
    M, N = size(state)
    
    step = 1<<(b1-1)
    step_2 = 1<<b1
    for j = step:step_2:M-1
        local temp::T
        local i_::Int
        @simd for b = j:j+step-1
            if testall(b, mask2)
                i = b+1
                i_ = flip(b, mask2) + 1
                if testall(b, mask2)
                    factor = T(im)
                else
                    factor = T(-im)
                end
                @inbounds @simd for c = 1:N
                    temp = state[i, c]
                    state[i, c] = state[i_, c]*factor
                    state[i_, c] = -temp*factor
                end
            end
        end
    end
    state
end
