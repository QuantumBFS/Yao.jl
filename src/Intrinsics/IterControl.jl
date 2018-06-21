using Compat
using Yao
using Yao.Intrinsics
using Yao.Blocks
using Yao.LuxurySparse
using StaticArrays: SVector, SMatrix

# add a tag initial control
"""
    IterControl{N, C}

N is the size of hilber space, C is the number of shifts.
"""
struct IterControl{N, C, S}
    base::Int
    masks::SVector{C, Int}
    ks::SVector{C, Int}
end

function IterControl{N}(base::Int, masks, ks) where N
    C=length(ks)
    IterControl{N, C, masks[1]}(base, SVector{C}(masks), SVector{C}(ks))
end

Base.length(ic::IterControl{N}) where N = N
Base.eltype(::Type{IterControl}) = Int
Base.start(::IterControl) = 0
Base.done(ic::IterControl{N}, state::Int) where N = state == N
function Base.next(ic::IterControl{N, C}, state::Int) where {N, C}
    res = state
    for s in 1:C
        res = lmove(res, ic.masks[s], ic.ks[s])
    end
    res+ic.base, state+1
end
lmove(b::Int, mask::Int, k::Int)::Int = (b&~mask)<<k + (b&mask)

# the factory of IterControl
function itercontrol(num_bit::Int, poss::Vector{Int}, vals::Vector{Int})
    base = bmask(poss[vals.!=0]...)
    masks, ks = group_shift(num_bit, poss)
    IterControl{1<<(num_bit-length(poss))}(base, masks, ks)
end

function group_shift(num_bit::Int, poss::Vector{Int})
    poss |> sort!
    masks = Int[]
    ns = Int[]
    k_pre = -1
    for k in poss
        if k == k_pre+1
            ns[end] += 1
        else
            push!(masks, bmask(0:k-1))
            push!(ns, 1)
        end
        k_pre = k
    end
    masks, ns
end

function controldo(func::Function, ic::IterControl{N, C}) where {N, C}
    for i in 0:N-1
        for s in 1:C
            i = lmove(i, ic.masks[s], ic.ks[s])
        end
        func(i+ic.base)
    end
end

################### Test for subspace and itercontrol #################
using Compat.Test

@testset "private functions: group_shift and lmove" begin
    @test group_shift(5, [1,2,5]) == ([0, 15], [2, 1])
    @test group_shift(5, [2,3]) == ([1], [2])
    @test group_shift(5, [1,3,5]) == ([0, 3, 15], [1, 1, 1])

    @test lmove(5, 1, 2) |> bin == "10001"
end

@testset "iterator interface" begin
    v = randn(ComplexF64, 1<<4)
    it = itercontrol(4, [3],[1])
    vec = Int[]
    it2 = itercontrol(4, [3, 4], [0, 0])
    for i in it2
        push!(vec, i)
    end
    @test vec == [0,1,2,3]

    vec = Int[]
    it4 = itercontrol(4, [4,2, 1], [1, 1, 1])
    for i in it4
        push!(vec, i)
    end
    @test vec == [11, 15]
    @test (rrr=copy(v); controldo(x->mulrow!(rrr, x+1, -1.0), it4); rrr) ≈ mat(control(4, (4,2), 1=>Z)) * v
    nbit = 8
    it = itercontrol(nbit, [3],[1])
    V = randn(ComplexF64, 1<<nbit)
    res = mat(kron(nbit, 3=>X))*V
    @test (rrr=copy(V); controldo(x->swaprows!(rrr, x+1, x-3), it); rrr) ≈ res
    @test (rrr=copy(V); controldo(x->mulrow!(rrr, x+1, -1), itercontrol(nbit, [3,7, 6], [1, 1, 1])); rrr) ≈ mat(control(nbit, (3,7), 6=>Z)) * V
end


using BenchmarkTools
#const nbit = 16
#const V = randn(ComplexF64, 1<<nbit)

#const res4 = copy(V)
#it = itercontrol(nbit, [3],[1])
#@benchmark controldo(x->swaprows!($res4, x+1, x-3), $it)
#@benchmark for i in $it swaprows!($res4, i+1, i-3) end
#@benchmark controldo($(x->x), $it)
