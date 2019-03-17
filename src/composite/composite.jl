using YaoBase

export CompositeBlock

"""
    CompositeBlock{N, T} <: AbstractBlock{N, T}

Abstract supertype which composite blocks will inherit from. Composite blocks
are blocks composited from other [`AbstractBlock`](@ref)s, thus it is a `AbstractBlock`
as well.
"""
abstract type CompositeBlock{N, T} <: AbstractBlock{N, T} end

"""
    SubBlocks(x)

Returns an iterator of the sub-blocks of a composite block. Default is empty.
"""
SubBlocks(x::CompositeBlock) = ()

"""
    chsubblocks(composite_block, itr)

Change the sub-blocks of a [`CompositeBlock`](@ref) with given iterator `itr`.
"""
@interface chsubblocks(::CompositeBlock, itr)

YaoBase.isunitary(m::CompositeBlock) = all(isunitary, subblocks(m)) || isunitary(mat(m))
YaoBase.ishermitian(m::CompositeBlock) = all(ishermitian, subblocks(m)) || ishermitian(mat(m))
YaoBase.isreflexive(m::CompositeBlock) = all(isreflexive, subblocks(m)) || isreflexive(mat(m))

"""
    AbstractContainer{N, T} <: CompositeBlock{N, T}

Abstract type for container block. Container blocks are blocks contain a single
block. Container block should have a
"""
abstract type AbstractContainer{N, T} <: CompositeBlock{N, T} end

"""
    contained_block(x::AbstractContainer)

Return the contained block.
"""
@interface contained_block(x::AbstractContainer) = x.block
SubBlocks(x::AbstractContainer) = (contained_block(x), )

"""
    chcontained_block(x::AbstractContainer, blk)

Create a new [`AbstractContainer`](@ref) with given sub-block. This uses
[`chsubblocks`](@ref) by default.
"""
@interface chcontained_block(x::AbstractContainer, blk)

chsubblocks(x::AbstractContainer, itr) = chcontained_block(x, first(itr))

# NOTE: this is a holy trait, no overhead, don't use methods on this
abstract type PreserveStyle end
struct PreserveAll <: PreserveStyle end
struct PreserveProperty{F} <: PreserveStyle end
struct PreserveNothing <: PreserveStyle end

PreserveStyle(c::AbstractContainer) = PreserveNothing()

for METHOD in (:ishermitian, :isreflexive, :isunitary)
    @eval begin
        # forward to trait
        YaoBase.$METHOD(x::AbstractContainer) = $METHOD(PreserveStyle(x), x)
        # forward contained block property
        YaoBase.$METHOD(::PreserveAll, c::AbstractContainer) = $METHOD(contained_block(c))
        # forward to default property by calculating the matrix
        YaoBase.$METHOD(::PreserveNothing, c::AbstractContainer) = $METHOD(mat(c))
        # preseve each property
        YaoBase.$METHOD(::PreserveProperty{$(QuoteNode(METHOD))}, c::AbstractContainer) =
            $METHOD(contained_block(c))
        # fallback
        YaoBase.$METHOD(::PreserveStyle, c::AbstractContainer) = $METHOD(contained_block(c))
    end
end


include("chain.jl")
include("kron.jl")
include("control.jl")
include("roller.jl")
include("put_block.jl")
include("repeated.jl")
include("concentrator.jl")
include("tag/tag.jl")
include("tag/cache.jl")
include("tag/dagger.jl")
