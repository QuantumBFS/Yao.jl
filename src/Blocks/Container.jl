# Additional APIs
export AbstractContainer
# Interface for Containers
export block, chblock

"""
    ContainerBlock{N, T} <: MatrixBlock{N, T}

abstract supertype which container blocks will inherit from.

# extended APIs

`block`: the block contained by this `ContainerBlock`

"""
abstract type AbstractContainer{N, T} <: MatrixBlock{N, T} end
subblocks(c::AbstractContainer) = (c |> block,)
chsubblocks(pb::AbstractContainer, blk) = chblock(pb, blk |> first)

"""
    block(container::AbstractContainer) -> AbstractBlock

get the contained block (i.e. subblock) of a container.
"""
function block end

"""
    chblock(block, blk)

change the block of a container.
"""
function chblock end

"""
    istraitkeeper(block) -> Bool

change the block of a container.
"""
function istraitkeeper end
istraitkeeper(::AbstractContainer) = Val(false)

for METHOD in (:ishermitian, :isreflexive, :isunitary)
    @eval $METHOD(c::AbstractContainer) = $METHOD(c, istraitkeeper(c))
    @eval $METHOD(c::AbstractContainer, ::Val{true}) = $METHOD(block(c))
    @eval $METHOD(c::AbstractContainer, ::Val{false}) = $METHOD(mat(c))
end

include("PutBlock.jl")
include("Control.jl")
include("Repeated.jl")
include("Concentrator.jl")
include("TagBlock.jl")

########## common interfaces are defined here! ##############
for BLOCKTYPE in (:PutBlock, :ControlBlock, :RepeatedBlock, :Concentrator)
    @eval block(dg::$BLOCKTYPE) = dg.block
end
