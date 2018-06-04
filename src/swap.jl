using Yao

using Yao.Intrinsics
using Yao.LuxurySparse
import Yao.Intrinsics: basis


###### PUT into APIS ##########
function swapbits2(b::Int, mask12::Int)::Int
    bm = b&mask12
    if bm!=0 && bm!=mask12
        b ⊻= mask12
    end
    b
end

apply2mat(applyfunc!::Function, num_bit::Int) = applyfunc!(eye(Complex128, 1<<num_bit))
basis(state::AbstractArray)::UnitRange{DInt} = UnitRange{DInt}(0, size(state, 1)-1)

##############################

function swapgate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) where MT<:Number
    mask = bmask(b1, b2)
    order = map(b->swapbits2(b, mask) + 1, basis(num_bit))
    PermMatrix(order, ones(MT, 1<<num_bit))
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
