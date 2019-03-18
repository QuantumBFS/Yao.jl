using YaoBase
export RepeatedBlock, repeat

"""
    RepeatedBlock <: AbstractContainer

Repeat the same block on given locations.
"""
struct RepeatedBlock{N, C, GT <: AbstractBlock, T} <: AbstractContainer{N, T}
    block::GT
    addrs::NTuple{C, Int}
end

function RepeatedBlock{N}(block::AbstractBlock{M, T}, addrs::NTuple{C, Int}) where {N, M, T, C}
    @assert_addrs N Tuple(i:i+M-1 for i in addrs)
    return RepeatedBlock{N, C, typeof(block), T}(block, addrs)
end

function RepeatedBlock{N}(block::GT) where {N, M, T, GT <: AbstractBlock{M, T}}
    return RepeatedBlock{N, N, GT, T}(block, Tuple(1:M:N-M+1))
end

"""
    repeat(n, x::AbstractBlock[, addrs]) -> RepeatedBlock{n}

Create a [`RepeatedBlock`](@ref) with total number of qubits `n` and the block
to repeat on given address or on all the address.
"""
Base.repeat(n::Int, x::AbstractBlock, addrs::Int...) =
    repeat(n, x, addrs)
Base.repeat(n::Int, x::AbstractBlock, addrs::NTuple{C, Int}) where C =
    RepeatedBlock{n}(x, addrs)
Base.repeat(n::Int, x::AbstractBlock) = RepeatedBlock{n}(x)

"""
    repeat(x::AbstractBlock, addrs)

Lazy curried version of [`repeat`](@ref).
"""
Base.repeat(x::AbstractBlock, addrs) = @λ(n->repeat(n, x, params...,))

occupied_locations(x::RepeatedBlock) = Iterators.flatten(k:k+nqubits(x.block)-1 for k in x.addrs)
chcontained_block(x::RepeatedBlock{N}, blk) where N = RepeatedBlock{N}(blk, x.addrs)
PreserveProperty(x::RepeatedBlock) = PreserveAll()

mat(rb::RepeatedBlock{N}) where N = hilbertkron(N, fill(mat(rb.block), length(rb.addrs)), [rb.addrs...])
mat(rb::RepeatedBlock{N, 0, GT, T}) where {N, GT, T} = IMatrix{1<<N, T}()

function apply!(r::AbstractRegister, rp::RepeatedBlock)
    m  = mat(rp.block)
    for addr in rp.addrs
        instruct!(matvec(r.state), mat(rp.block), Tuple(addr:addr+nqubits(rp.block)-1))
    end
    return r
end

# specialization
for G in [:X, :Y, :Z, :S, :T, :Sdag, :Tdag]
    GT = Symbol(G, :Gate)
    @eval function apply!(r::AbstractRegister, rp::RepeatedBlock{N, C, <:$GT}) where {N, C}
        for addr in rp.addrs
            instruct!(matvec(r.state), Val($(QuoteNode(G))), Tuple(addr:addr+nqubits(rp.block)-1))
        end
        return r
    end
end

apply!(reg::AbstractRegister, rp::RepeatedBlock{N, 0}) where N = reg

cache_key(rb::RepeatedBlock) = (rb.addrs, cache_key(rb.block))

Base.adjoint(blk::RepeatedBlock{N}) where N = RepeatedBlock{N}(adjoint(blk.block), blk.addrs)
Base.copy(x::RepeatedBlock{N}) where N = RepeatedBlock{N}(x.block, x.addrs)
Base.:(==)(A::RepeatedBlock, B::RepeatedBlock) = A.addrs == B.addrs && A.block == B.block

function YaoBase.iscommute(x::RepeatedBlock{N}, y::RepeatedBlock{N}) where N
    if x.addrs == y.addrs
        return iscommute(x.block, y.block)
    else
        iscommute_fallback(x, y)
    end
end
