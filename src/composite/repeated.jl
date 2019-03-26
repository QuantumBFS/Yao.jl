using YaoBase
export RepeatedBlock, repeat

"""
    RepeatedBlock <: AbstractContainer

Repeat the same block on given locations.
"""
struct RepeatedBlock{N, C, GT <: AbstractBlock, T} <: AbstractContainer{N, T, GT}
    content::GT
    locs::NTuple{C, Int}
end

function RepeatedBlock{N}(block::AbstractBlock{M, T}, locs::NTuple{C, Int}) where {N, M, T, C}
    @assert_locs N Tuple(i:i+M-1 for i in locs)
    return RepeatedBlock{N, C, typeof(block), T}(block, locs)
end

function RepeatedBlock{N}(block::GT) where {N, M, T, GT <: AbstractBlock{M, T}}
    return RepeatedBlock{N, N, GT, T}(block, Tuple(1:M:N-M+1))
end

"""
    repeat(n, x::AbstractBlock[, locs]) -> RepeatedBlock{n}

Create a [`RepeatedBlock`](@ref) with total number of qubits `n` and the block
to repeat on given location or on all the locations.
"""
Base.repeat(n::Int, x::AbstractBlock, locs::Int...) =
    repeat(n, x, locs)
Base.repeat(n::Int, x::AbstractBlock, locs::NTuple{C, Int}) where C =
    RepeatedBlock{n}(x, locs)
Base.repeat(n::Int, x::AbstractBlock) = RepeatedBlock{n}(x)

"""
    repeat(x::AbstractBlock, locs)

Lazy curried version of [`repeat`](@ref).
"""
Base.repeat(x::AbstractBlock, locs) = @λ(n->repeat(n, x, params...,))

occupied_locs(x::RepeatedBlock) = Iterators.flatten(k:k+nqubits(x.content)-1 for k in x.locs)
chsubblocks(x::RepeatedBlock{N}, blk::AbstractBlock) where N = RepeatedBlock{N}(blk, x.locs)
PreserveProperty(x::RepeatedBlock) = PreserveAll()

mat(rb::RepeatedBlock{N}) where N = hilbertkron(N, fill(mat(rb.content), length(rb.locs)), [rb.locs...])
mat(rb::RepeatedBlock{N, 0, GT, T}) where {N, GT, T} = IMatrix{1<<N, T}()

function apply!(r::AbstractRegister, rp::RepeatedBlock)
    m  = mat(rp.content)
    for addr in rp.locs
        instruct!(matvec(r.state), mat(rp.content), Tuple(addr:addr+nqubits(rp.content)-1))
    end
    return r
end

# specialization
for G in [:X, :Y, :Z, :S, :T, :Sdag, :Tdag]
    GT = Expr(:(.), :ConstGate, QuoteNode(Symbol(G, :Gate)))
    @eval function apply!(r::AbstractRegister, rp::RepeatedBlock{N, C, <:$GT}) where {N, C}
        for addr in rp.locs
            instruct!(matvec(r.state), Val($(QuoteNode(G))), Tuple(addr:addr+nqubits(rp.content)-1))
        end
        return r
    end
end

apply!(reg::AbstractRegister, rp::RepeatedBlock{N, 0}) where N = reg

cache_key(rb::RepeatedBlock) = (rb.locs, cache_key(rb.content))

Base.adjoint(blk::RepeatedBlock{N}) where N = RepeatedBlock{N}(adjoint(blk.content), blk.locs)
Base.copy(x::RepeatedBlock{N}) where N = RepeatedBlock{N}(x.content, x.locs)
Base.:(==)(A::RepeatedBlock, B::RepeatedBlock) = A.locs == B.locs && A.content == B.content

function YaoBase.iscommute(x::RepeatedBlock{N}, y::RepeatedBlock{N}) where N
    if x.locs == y.locs
        return iscommute(x.content, y.content)
    else
        iscommute_fallback(x, y)
    end
end
