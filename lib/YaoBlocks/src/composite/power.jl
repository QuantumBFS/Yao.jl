export Power

using LinearAlgebra
using LegibleLambdas

"""
    Power{D,GT<:AbstractBlock,PT<:Real} <: AbstractContainer{GT,D}
    Power(block, pow) -> Power

Repeat the same block `content` `pow` times
"""
struct Power{D,BT<:AbstractBlock,PT<:Integer} <: AbstractContainer{BT,D}
    content::BT
    pow::PT
end

function Power(content::BT, pow::PT) where {D,BT<:AbstractBlock{D},PT}
    if pow < 0 && !isunitary(content)
        throw(ArgumentError("negative power requires a unitary block"))
    end
    Power{D,BT,PT}(content, pow)
end
Power(content::LegibleLambda, pow::PT) where {PT} = @λ(n -> Power(content(n), pow))

nqudits(pb::Power) = nqudits(pb.content)
chsubblocks(pb::Power, blk::AbstractBlock) = Power(blk, pb.pow)
occupied_locs(pb::Power) = occupied_locs(pb.content)

function mat(::Type{T}, pb::Power{D}) where {T, D}
    pb.pow  >= 0 && return mat(T, pb.content)^pb.pow
    return mat(T, adjoint(pb.content))^(-pb.pow)  # unitary: U^(-n) = (U†)^n
end

function YaoAPI.unsafe_apply!(r::AbstractRegister, pb::Power{D}) where {D}
    blk = pb.pow >= 0 ? pb.content : adjoint(pb.content)
    for _ in 1:abs(pb.pow)
        YaoAPI.unsafe_apply!(r, blk)
    end
    return r
end

nparameters(pb::Power) = nparameters(pb.content)
Base.adjoint(pb::Power) = Power(adjoint(pb.content), pb.pow)
Base.:(==)(a::Power, b::Power) = a.pow == b.pow && a.content == b.content
Base.copy(pb::Power) = Power(pb.content, pb.pow)
cache_key(pb::Power) = (pb.pow, cache_key(pb.content))
PropertyTrait(::Power) = PreserveAll()
