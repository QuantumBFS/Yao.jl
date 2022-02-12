export NoParams

struct NoParams{N,D,BT<:AbstractBlock{N,D}} <: TagBlock{BT,N,D}
    content::BT
end

YaoBlocks.parameters!(out, x::NoParams) = out
YaoBlocks.nparameters(x::NoParams) = 0
YaoBlocks.niparams(x::NoParams) = 0
YaoBlocks.mat(::Type{T}, x::NoParams) where {T} = mat(T, content(x))
YaoBlocks.PropertyTrait(x::NoParams) = PreserveAll()
YaoBlocks.dispatch!(f::Union{Function,Nothing}, x::NoParams, it::YaoBlocks.Dispatcher) = x
YaoBlocks.generic_dispatch!(f::Union{Function,Nothing}, x::NoParams, it::YaoBlocks.Dispatcher) = x
Base.adjoint(x::NoParams) = NoParams(adjoint(content(x)))
YaoBlocks.chsubblocks(x::NoParams, blk::AbstractBlock) = NoParams(blk)