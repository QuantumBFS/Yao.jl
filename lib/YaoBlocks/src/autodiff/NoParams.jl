export NoParams

struct NoParams{D,BT<:AbstractBlock{D}} <: TagBlock{BT,D}
    content::BT
end

YaoBlocks.parameters!(out, x::NoParams) = out
YaoBlocks.nparameters(x::NoParams) = 0
YaoBlocks.niparams(x::NoParams) = 0
YaoBlocks.mat(::Type{T}, x::NoParams) where {T} = mat(T, content(x))
YaoAPI.unsafe_apply!(r::AbstractRegister, pb::NoParams) = YaoAPI.unsafe_apply!(r, pb.content)
YaoBlocks.PropertyTrait(x::NoParams) = PreserveAll()
YaoBlocks.dispatch!(f::Union{Function,Nothing}, x::NoParams, it::YaoBlocks.Dispatcher) = x
YaoBlocks.generic_dispatch!(f::Union{Function,Nothing}, x::NoParams, it::YaoBlocks.Dispatcher) = x
Base.adjoint(x::NoParams) = NoParams(adjoint(content(x)))
YaoBlocks.chsubblocks(x::NoParams, blk::AbstractBlock) = NoParams(blk)
YaoBlocks.gatecount!(c::NoParams, storage::AbstractDict) = YaoBlocks.gatecount!(c.content, storage)