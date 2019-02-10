export RepeatedBlock

"""
    RepeatedBlock{N, C, GT, T} <: AbstractContainer{N, T}

repeat the same block on given addrs.
"""
mutable struct RepeatedBlock{N, C, GT<:MatrixBlock, T} <: AbstractContainer{N, T}
    block::GT
    addrs::NTuple{C, Int}

    function RepeatedBlock{N, C, GT, T}(block, addrs) where {N, M, C, T, GT<:MatrixBlock{M, T}}
        assert_addr_safe(N, UnitRange{Int}[i:i+M-1 for i in addrs])
        length(addrs) == C || throw(ArgumentError("Repeat number mismatch!"))
        new{N, C, GT, T}(block, addrs)
    end
end

function RepeatedBlock{N}(block::GT) where {N, M, T, GT <: MatrixBlock{M, T}}
    RepeatedBlock{N, N, GT, T}(block, (1:M:N-M+1..., ))
end

function RepeatedBlock{N}(block::GT, addrs::NTuple) where {N, M, T, GT <: MatrixBlock{M, T}}
    RepeatedBlock{N, length(addrs), GT, T}(block, addrs)
end

Base.:(==)(A::RepeatedBlock, B::RepeatedBlock) = A.addrs == B.addrs && A.block == B.block
addrs(rb::RepeatedBlock) = rb.addrs
usedbits(rb::RepeatedBlock) = vcat([i.+(0:nqubits(rb.block)-1) for i in addrs(rb)]...)
Base.copy(x::RepeatedBlock) = typeof(x)(x.block, x.addrs)
chblock(pb::RepeatedBlock{N}, blk::AbstractBlock) where N = RepeatedBlock{N}(blk, pb.addrs)

istraitkeeper(::RepeatedBlock) = Val(true)
YaoBase.iscommute(x::RepeatedBlock{N}, y::RepeatedBlock{N}) where N = x.addrs == y.addrs ? iscommute(x.block, y.block) : _default_iscommute(x, y)

mat(rb::RepeatedBlock{N}) where N = hilbertkron(N, fill(mat(rb.block), length(rb.addrs)), [rb.addrs...])
mat(rb::RepeatedBlock{N, 0, GT, T}) where {N, GT, T} = IMatrix{1<<N, T}()

Base.adjoint(blk::RepeatedBlock{N}) where N = RepeatedBlock{N}(adjoint(blk.block), blk.addrs)
function apply!(reg::AbstractRegister, rp::RepeatedBlock{N}) where N
    m  = mat(rp.block)
    for addr in rp.addrs
        instruct!(reg.state |> matvec, m, ((addr:addr+nqubits(rp.block)-1)...,))
    end
    reg
end

apply!(reg::AbstractRegister, rp::RepeatedBlock{N, 0}) where N = reg

function Base.hash(rb::RepeatedBlock, h::UInt)
    hashkey = hash(objectid(rb), h)
    hashkey = hash(rb.block, hashkey)
    hashkey = hash(rb.addrs, hashkey)
    hashkey
end

function Base.:(==)(lhs::RepeatedBlock{N, C, GT, T}, rhs::RepeatedBlock{N, C, GT, T}) where {N, T, C, GT}
    (lhs.block == rhs.block) && (lhs.addrs == rhs.addrs)
end

function cache_key(rb::RepeatedBlock)
    cache_key(rb.block)
end

function print_block(io::IO, rb::RepeatedBlock{N}) where N
    printstyled(io, "repeat on ("; bold=true, color=color(RepeatedBlock))
    for i in eachindex(rb.addrs)
        printstyled(io, rb.addrs[i]; bold=true, color=color(RepeatedBlock))
        if i != lastindex(rb.addrs)
            printstyled(io, ", "; bold=true, color=color(RepeatedBlock))
        end
    end
    printstyled(io, ")"; bold=true, color=color(RepeatedBlock))
end
