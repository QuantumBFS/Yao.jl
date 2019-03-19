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
    subblocks(x)

Returns an iterator of the sub-blocks of a composite block. Default is empty.
"""
subblocks(x::CompositeBlock) = ()

"""
    chsubblocks(composite_block, itr)

Change the sub-blocks of a [`CompositeBlock`](@ref) with given iterator `itr`.
"""
@interface chsubblocks(x::CompositeBlock, itr) = chsubblocks(x, itr...) # fallback

YaoBase.isunitary(m::CompositeBlock) = all(isunitary, subblocks(m)) || isunitary(mat(m))
YaoBase.ishermitian(m::CompositeBlock) = all(ishermitian, subblocks(m)) || ishermitian(mat(m))
YaoBase.isreflexive(m::CompositeBlock) = all(isreflexive, subblocks(m)) || isreflexive(mat(m))

"""
    AbstractContainer{N, T} <: CompositeBlock{N, T}

Abstract type for container block. Container blocks are blocks contain a single
block. Container block should have a
"""
abstract type AbstractContainer{N, T, BT <: AbstractBlock} <: CompositeBlock{N, T} end

Base.parent(x::AbstractContainer) = x.block
subblocks(x::AbstractContainer) = (parent(x), )

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
        # forward parent block property
        YaoBase.$METHOD(::PreserveAll, c::AbstractContainer) = $METHOD(parent(c))
        # forward to default property by calculating the matrix
        YaoBase.$METHOD(::PreserveNothing, c::AbstractContainer) = $METHOD(mat(c))
        # preseve each property
        YaoBase.$METHOD(::PreserveProperty{$(QuoteNode(METHOD))}, c::AbstractContainer) =
            $METHOD(parent(c))
        # fallback
        YaoBase.$METHOD(::PreserveStyle, c::AbstractContainer) = $METHOD(parent(c))
    end
end

function Base.:(==)(lhs::AbstractContainer{N, T, BT},
        rhs::AbstractContainer{N, T, BT}) where {N, T, BT}
    return parent(lhs) == parent(rhs)
end

include("chain.jl")
include("kron.jl")
include("control.jl")
include("roller.jl")
include("put_block.jl")
include("repeated.jl")
include("concentrator.jl")
include("cache.jl")
