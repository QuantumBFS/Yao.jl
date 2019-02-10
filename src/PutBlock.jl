export PutBlock

"""
    PutBlock{N, C, GT, T} <: AbstractContainer{N, T}

put a block on given addrs.
"""
mutable struct PutBlock{N, C, GT<:MatrixBlock, T} <: AbstractContainer{N, T}
    block::GT
    addrs::NTuple{C, Int}

    function PutBlock{N, C, GT, T}(block::GT, addrs::NTuple{C, Int}) where {N, C, T, GT<:MatrixBlock{C, T}}
        assert_addr_safe(N, [addrs...])
        length(addrs) == C || throw(ArgumentError("Repeat number mismatch!"))
        new{N, C, GT, T}(block, addrs)
    end
end

function PutBlock{N}(block::GT, addrs::NTuple) where {N, C, T, GT <: MatrixBlock{C, T}}
    PutBlock{N, C, GT, T}(block, addrs)
end

addrs(pb::PutBlock) = pb.addrs
usedbits(pb::PutBlock) = [pb.addrs...]
Base.copy(x::PutBlock) = typeof(x)(x.block, x.addrs)
Base.adjoint(blk::PutBlock{N}) where N = PutBlock{N}(adjoint(blk.block), blk.addrs)
chblock(pb::PutBlock{N, C}, blk::MatrixBlock{C}) where {N, C} = PutBlock{N}(blk, pb.addrs)

istraitkeeper(::PutBlock) = Val(true)
YaoBase.iscommute(x::PutBlock{N}, y::PutBlock{N}) where N = x.addrs == y.addrs ? iscommute(x.block, y.block) : _default_iscommute(x, y)

# TODO
mat(pb::PutBlock{N, 1}) where N = u1mat(N, mat(pb.block), pb.addrs...)
mat(pb::PutBlock{N, C}) where {N, C} = unmat(N, mat(pb.block), pb.addrs)
#mat(pb::PutBlock{N, 1}) where N = hilbertkron(N, [mat(pb.block)], [pb.addrs...])
function apply!(r::AbstractRegister, pb::PutBlock{N}) where N
    N == nactive(r) || throw(QubitMismatchError("register Size $(nactive(r)) mismatch with block size $N"))
    instruct!(r.state |> matvec, mat(pb.block), pb.addrs)
    r
end

function Base.hash(pb::PutBlock, h::UInt)
    hashkey = hash(objectid(pb), h)
    hashkey = hash(pb.block, hashkey)
    hashkey = hash(pb.addrs, hashkey)
    hashkey
end

function Base.:(==)(lhs::PutBlock{N, C, GT, T}, rhs::PutBlock{N, C, GT, T}) where {N, T, C, GT}
    (lhs.block == rhs.block) && (lhs.addrs == rhs.addrs)
end

cache_key(pb::PutBlock) = cache_key(pb.block)

function print_block(io::IO, pb::PutBlock{N}) where N
    printstyled(io, "put on ("; bold=true, color=color(PutBlock))
    for i in eachindex(pb.addrs)
        printstyled(io, pb.addrs[i]; bold=true, color=color(PutBlock))
        if i != lastindex(pb.addrs)
            printstyled(io, ", "; bold=true, color=color(PutBlock))
        end
    end
    printstyled(io, ")"; bold=true, color=color(PutBlock))
end
