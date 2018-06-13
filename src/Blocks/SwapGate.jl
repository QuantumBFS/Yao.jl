export Swap

struct Swap{N, T} <: PrimitiveBlock{N, T}
    addr1::Int
    addr2::Int

    function Swap{N, T}(addr1::Int, addr2::Int) where {N, T}
        _assert_addr_inbounds(N, [addr1:addr1, addr2:addr2])
        new{N, T}(addr1, addr2)
    end
end

function mat(g::Swap{N, T}) where {N, T}
    mask = bmask(g.addr1, g.addr2)
    order = map(b->swapbits(b, mask) + 1, basis(N))
    PermMatrix(order, ones(T, 1<<N))
end

apply!(r::AbstractRegister, rb::Swap) = swapapply!(state(r) |> matvec, rb.addr1, rb.addr2)

function swapapply!(state::VecOrMat{T}, b1::Int, b2::Int) where T
    mask1 = bmask(b1)
    mask2 = bmask(b2)
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
    state
end

function hash(swap::Swap, h::UInt)
    hashkey = hash(swap.addr1, h)
    hashkey = hash(swap.addr2, hashkey)
    hashkey
end

function ==(lhs::Swap, rhs::Swap)
    (lhs.addr1 == rhs.addr1) && (lhs.addr2 == rhs.addr2)
end

function print_block(io::IO, swap::Swap)
    printstyled(io, "swap(", swap.addr1, ", ", swap.addr2, ")"; bold=true, color=color(Swap))
end
