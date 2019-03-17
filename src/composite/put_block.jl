export PutBlock, put

"""
    PutBlock <: AbstractContainer

Type for putting a block at given locations.
"""
struct PutBlock{N, M, C, T, GT <: AbstractBlock} <: AbstractContainer{N, T}
    block::GT
    addrs::NTuple{C, Int}

    function PutBlock{N}(block::GT, addrs::NTuple{C, Int}) where {N, M, C, T, GT <: AbstractBlock{M, T}}
        @assert_addrs N addrs
        return new{N, M, C, T, GT}(block, addrs)
    end
end

"""
    put(total::Int, pair)

Create a [`PutBlock`](@ref) with total number of active qubits, and a pair of
address and block to put on.
"""
put(total::Int, pa::Pair{NTuple{M, Int}, <:AbstractBlock}) where M =
    PutBlock{total}(pa.second, pa.first)
put(total::Int, pa::Pair{Int, <:AbstractBlock}) = PutBlock{total}(pa.second, (pa.first, ))

"""
    put(pair) -> f(n)

Lazy curried version of [`put`](@ref).
"""
put(pa::Pair) = @λ(n -> put(n, pa))

OccupiedLocations(x::PutBlock) = x.addrs
chcontained_block(x::PutBlock{N, M}, b::AbstractBlock{M}) where {N, M} = PutBlock{N}(b, x.addrs)
PreserveStyle(::PutBlock) = PreserveAll()
cache_key(pb::PutBlock) = cache_key(pb.block)

mat(pb::PutBlock{N, 1}) where N = u1mat(N, mat(pb.block), pb.addrs...)
mat(pb::PutBlock{N, C}) where {N, C} = unmat(N, mat(pb.block), pb.addrs)

function apply!(r::ArrayReg, pb::PutBlock{N}) where N
    N == nactive(r) || throw(QubitMismatchError("register size $(nactive(r)) mismatch with block size $N"))
    instruct!(matvec(r.state), mat(pb.block), pb.addrs)
    return r
end

# specialization
for G in [:X, :Y, :Z, :T, :S, :Sdag, :Tdag]
    GT = Symbol(G, :Gate)
    @eval function apply!(r::ArrayReg, pb::PutBlock{N, C, T, <:$GT}) where {N, C, T}
        N == nactive(r) || throw(QubitMismatchError("register size $(nactive(r)) mismatch with block size $N"))
        instruct!(matvec(r.state), Val($(QuoteNode(G))), pb.addrs)
        return r
    end
end

Base.adjoint(x::PutBlock{N}) where N = PutBlock{N}(adjoint(x), x.addrs)
Base.copy(x::PutBlock{N}) where N = PutBlock{N}(x.block, x.addrs)
function Base.:(==)(lhs::PutBlock{N, C, GT, T}, rhs::PutBlock{N, C, GT, T}) where {N, T, C, GT}
    return (lhs.block == rhs.block) && (lhs.addrs == rhs.addrs)
end

function YaoBase.iscommute(x::PutBlock{N}, y::PutBlock{N}) where N
    if x.addrs == y.addrs
        return iscommute(x.block, y.block)
    else
        return iscommute_fallback(x, y)
    end
end
