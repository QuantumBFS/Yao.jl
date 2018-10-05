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
    block(container)

get an iterator that iterate through all sub-blocks.
"""
function block end

"""
    chblock(block, blk)

set the block of a container.
"""
function chblock end

print_subblocks(io::IO, tree::AbstractContainer, depth, charset, active_levels) = print_subblocks(io, block(tree), depth, charset, active_levels)

include("PutBlock.jl")
include("Control.jl")
include("Repeated.jl")
include("Concentrator.jl")
include("TagBlock.jl")

########## common interfaces are defined here! ##############
for BLOCKTYPE in (:PutBlock, :ControlBlock, :RepeatedBlock, :Concentrator, :Daggered, :CachedBlock, :Scale)
    @eval block(dg::$BLOCKTYPE) = dg.block
end
