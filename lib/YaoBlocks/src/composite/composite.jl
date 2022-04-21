using YaoAPI

"""
    content(x)

Returns the content of `x`.
"""
content(x::AbstractContainer) = x.content


"""
    chcontent(x, blk)

Create a similar block of `x` and change its content to blk.
"""
chcontent(x::AbstractContainer, blk) = chsubblocks(x, blk)

subblocks(x::AbstractContainer) = (content(x),)
# NOTE: there's only one block inside, so we expand the iterator
# this would error if there's more than one block in it. But will
# work if there exactly one block.
chsubblocks(x::AbstractContainer, it) = chsubblocks(x, it...)

# throw better error msg when no chsubblocks is overloaded
# for this container block
# since every AbstractContainer should overload this method
chsubblocks(x::AbstractContainer, it::AbstractBlock) =
    throw(NotImplementedError(:chsubblocks, (x, it)))

# TODO:
#   - use simple traits instead
#   - each property should have a trait
# NOTE: this is a holy trait, no overhead, don't use methods on this
"""
    PropertyTrait
    PropertyTrait(::AbstractContainer) -> PropertyTrait

Typically, it can be `PreserveAll()` for those containers that do not change `ishermitian`, `isunitary` and `isreflexive` properties, otherwise fallback to `PreserveNothing`.
"""
abstract type PropertyTrait end
struct PreserveAll <: PropertyTrait end
struct PreserveNothing <: PropertyTrait end

PropertyTrait(c::AbstractContainer) = PreserveNothing()

for METHOD in (:(LinearAlgebra.ishermitian), :(YaoAPI.isreflexive), :(YaoAPI.isunitary))
    @eval begin
        # forward to trait
        $METHOD(x::AbstractContainer) = $METHOD(PropertyTrait(x), x)
        # forward parent block property
        $METHOD(::PreserveAll, c::AbstractContainer) = $METHOD(content(c))
        # forward to default property by calculating the matrix
        $METHOD(::PreserveNothing, c::AbstractContainer) = $METHOD(mat(c))
    end
end

include("chain.jl")
include("kron.jl")
include("control.jl")
include("put_block.jl")
include("repeated.jl")
include("subroutine.jl")
include("reduce.jl")
include("unitary_channel.jl")

chsubblocks(x::ChainBlock, it::AbstractBlock) = chsubblocks(x, (it,))
chsubblocks(x::KronBlock, it::AbstractBlock) = chsubblocks(x, (it,))
chsubblocks(x::Add, it::AbstractBlock) = chsubblocks(x, (it,))

# tag blocks
include("tag/tag.jl")
include("tag/cache.jl")
include("tag/dagger.jl")
include("tag/scale.jl")
