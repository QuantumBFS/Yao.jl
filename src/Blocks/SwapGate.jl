export Swap

struct Swap{N, T} <: PrimitiveBlock{N, T}
    line1::Int
    line2::Int

    Swap{N, T}(line1::Int, line2::Int) where {N, T} = new{N, T}(line1, line2)
end

function mat(g::Swap{N, T}) where {N, T}
    mask = bmask(g.line1, g.line2)
    order = map(b->swapbits(b, mask) + 1, basis(N))
    PermMatrix(order, ones(T, 1<<N))
end

function apply!(r::AbstractRegister{1}, rb::Swap)
    if nremains(r) == 0
        swapapply!(vec(state(r)), rb.line1, rb.line2)
    else
        swapapply!(state(r), rb.line1, rb.line2)
    end
end

function apply!(r::AbstractRegister, rb::Swap)
    swapapply!(state(r), rb.line1, rb.line2)
end

function swapapply!(state::Matrix{T}, b1::Int, b2::Int) where T
    mask1 = bmask(b1)
    mask2 = bmask(b2)
    mask12 = mask1|mask2
    M, N = size(state)

    @simd for b = basis(state)
        local temp::T
        local i_::Int
        if b&mask1==0 && b&mask2==mask2
            i = b+1
            i_ = b ⊻ mask12 + 1
            @simd for c = 1:N
                @inbounds temp = state[i, c]
                @inbounds state[i, c] = state[i_, c]
                @inbounds state[i_, c] = temp
            end
        end
    end
    state
end

function swapapply!(state::Vector{T}, b1::Int, b2::Int) where T
    mask1 = bmask(b1)
    mask2 = bmask(b2)
    mask12 = mask1|mask2
    M = length(state)

    @simd for b = basis(state)
        local temp::T
        local i_::Int
        if b&mask1==0 && b&mask2==mask2
            i = b+1
            i_ = b ⊻ mask12 + 1
            @inbounds temp = state[i]
            @inbounds state[i] = state[i_]
            @inbounds state[i_] = temp
        end
    end
    state
end

function hash(swap::Swap, h::UInt)
    hashkey = hash(swap.line1, h)
    hashkey = hash(swap.line2, hashkey)
    hashkey
end

function ==(lhs::Swap, rhs::Swap)
    (lhs.line1 == rhs.line1) && (lhs.line2 == rhs.line2)
end

function print_block(io::IO, swap::Swap)
    printstyled(io, "swap(", swap.line1, ", ", swap.line2, ")"; bold=true, color=color(Swap))
end
