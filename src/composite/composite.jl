using YaoBase

export CompositeBlock

"""
    CompositeBlock{N, T} <: AbstractBlock{N, T}

Abstract supertype which composite blocks will inherit from. Composite blocks
are blocks composited from other [`AbstractBlock`](@ref)s, thus it is a `AbstractBlock`
as well.
"""
abstract type CompositeBlock{N, T} <: AbstractBlock{N, T} end

YaoBase.isunitary(m::CompositeBlock) = all(isunitary, subblocks(m)) || isunitary(mat(m))
YaoBase.ishermitian(m::CompositeBlock) = all(ishermitian, subblocks(m)) || ishermitian(mat(m))
YaoBase.isreflexive(m::CompositeBlock) = all(isreflexive, subblocks(m)) || isreflexive(mat(m))

"""
    AbstractContainer{N, T} <: CompositeBlock{N, T}

Abstract type for container block. Container blocks are blocks contain a single
block. Container block should have a
"""
abstract type AbstractContainer{N, T, BT <: AbstractBlock} <: CompositeBlock{N, T} end

"""
    content(x)

Returns the content of `x`.
"""
@interface content(x::AbstractContainer) = x.content
subblocks(x::AbstractContainer) = (content(x), )
# NOTE: there's only one block inside, so we expand the iterator
# this would error if there's more than one block in it. But will
# work if there exactly one block.
chsubblocks(x::AbstractContainer, it) = chsubblocks(x, it...)

# throw better error msg when no chsubblocks is overloaded
# for this container block
# since every AbstractContainer should overload this method
chsubblocks(x::AbstractContainer, it::AbstractBlock) = throw(NotImplementedError(:chsubblocks, (x, it)))

# TODO:
#   - use simple traits instead
#   - each property should have a trait
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
        YaoBase.$METHOD(::PreserveAll, c::AbstractContainer) = $METHOD(content(c))
        # forward to default property by calculating the matrix
        YaoBase.$METHOD(::PreserveNothing, c::AbstractContainer) = $METHOD(mat(c))
        # preseve each property
        YaoBase.$METHOD(::PreserveProperty{$(QuoteNode(METHOD))}, c::AbstractContainer) =
            $METHOD(content(c))
        # fallback
        YaoBase.$METHOD(::PreserveStyle, c::AbstractContainer) = $METHOD(content(c))
    end
end

function Base.:(==)(lhs::AbstractContainer{N, T, BT},
        rhs::AbstractContainer{N, T, BT}) where {N, T, BT}
    return content(lhs) == content(rhs)
end

include("chain.jl")
include("kron.jl")
include("control.jl")
include("roller.jl")
include("put_block.jl")
include("repeated.jl")
include("concentrator.jl")
include("reduce.jl")
include("pauli_strings.jl")

chsubblocks(x::ChainBlock, it::AbstractBlock) = chsubblocks(x, (it, ))
chsubblocks(x::KronBlock, it::AbstractBlock) = chsubblocks(x, (it, ))
chsubblocks(x::Roller, it::AbstractBlock) = chsubblocks(x, (it, ))
chsubblocks(x::Prod, it::AbstractBlock) = chsubblocks(x, (it, ))
chsubblocks(x::Sum, it::AbstractBlock) = chsubblocks(x, (it, ))

# tag blocks
include("tag/tag.jl")
include("tag/cache.jl")
include("tag/dagger.jl")
include("tag/scale.jl")
