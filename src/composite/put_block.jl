export PutBlock, put

"""
    PutBlock <: AbstractContainer

Type for putting a block at given locations.
"""
struct PutBlock{N, C, GT <: AbstractBlock, T} <: AbstractContainer{GT, N, T}
    content::GT
    locs::NTuple{C, Int}

    function PutBlock{N}(block::GT, locs::NTuple{C, Int}) where {N, M, C, T, GT <: AbstractBlock{M, T}}
        @assert_locs_safe N locs
        @assert nqubits(block) == C "number of locations doesn't match the size of block"
        return new{N, C, GT, T}(block, locs)
    end
end

"""
    put(total::Int, pair)

Create a [`PutBlock`](@ref) with total number of active qubits, and a pair of
location and block to put on.
"""
put(total::Int, pa::Pair{NTuple{M, Int}, <:AbstractBlock}) where M =
    PutBlock{total}(pa.second, pa.first)
put(total::Int, pa::Pair{Int, <:AbstractBlock}) = PutBlock{total}(pa.second, (pa.first, ))
put(total::Int, pa::Pair{<:Any, <:AbstractBlock}) = PutBlock{total}(pa.second, Tuple(pa.first))

"""
    put(pair) -> f(n)

Lazy curried version of [`put`](@ref).
"""
put(pa::Pair) = @λ(n -> put(n, pa))

occupied_locs(x::PutBlock) = x.locs
chsubblocks(x::PutBlock{N}, b::AbstractBlock) where N = PutBlock{N}(b, x.locs)
PreserveStyle(::PutBlock) = PreserveAll()
cache_key(pb::PutBlock) = cache_key(pb.content)

mat(pb::PutBlock{N, 1}) where N = u1mat(N, mat(pb.content), pb.locs...)
mat(pb::PutBlock{N, C}) where {N, C} = unmat(N, mat(pb.content), pb.locs)

function apply!(r::ArrayReg, pb::PutBlock{N}) where N
    _check_size(r, pb)
    instruct!(matvec(r.state), mat(pb.content), pb.locs)
    return r
end

# specialization
for G in [:X, :Y, :Z, :T, :S, :Sdag, :Tdag]
    GT = Expr(:(.), :ConstGate, QuoteNode(Symbol(G, :Gate)))
    @eval function apply!(r::ArrayReg, pb::PutBlock{N, C, <:$GT, T}) where {N, C, T}
        _check_size(r, pb)
        instruct!(matvec(r.state), Val($(QuoteNode(G))), pb.locs)
        return r
    end
end

Base.adjoint(x::PutBlock{N}) where N = PutBlock{N}(adjoint(content(x)), x.locs)
Base.copy(x::PutBlock{N}) where N = PutBlock{N}(x.content, x.locs)
function Base.:(==)(lhs::PutBlock{N, C, GT, T}, rhs::PutBlock{N, C, GT, T}) where {N, T, C, GT}
    return (lhs.content == rhs.content) && (lhs.locs == rhs.locs)
end

function YaoBase.iscommute(x::PutBlock{N}, y::PutBlock{N}) where N
    if x.locs == y.locs
        return iscommute(x.content, y.content)
    else
        return iscommute_fallback(x, y)
    end
end
