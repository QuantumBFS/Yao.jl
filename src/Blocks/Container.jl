# Additional APIs
export AbstractContainer, NonParametricContainer
# Interface for Containers
export block, setblock!

"""
    ContainerBlock{N, T} <: MatrixBlock{N, T}

abstract supertype which container blocks will inherit from.

# extended APIs

`block`: the block contained by this `ContainerBlock`

"""
abstract type AbstractContainer{N, T} <: MatrixBlock{N, T} end
subblocks(c::AbstractContainer) = (c |> block,)

"""
    NonParametricContainer{N, T} <: AbstractContainer{N, T}

Simple container with no extra parameters.
"""
abstract type NonParametricContainer{N, T} <: AbstractContainer{N, T} end

"""
    block(container)

get an iterator that iterate through all sub-blocks.
"""
function block end

"""
    setblock!(container, blk)

set the block of a container.
"""
function setblock end

################# Interface for non-parametric containers #################
parameters(np::NonParametricContainer) = parameters(np |> block)
nparameters(np::NonParametricContainer) = nparameters(np |> block)
dispatch!(c::NonParametricContainer, params) = (dispatch!(c |> block, params); c)
dispatch!(f::Function, c::NonParametricContainer, itr) = (dispatch!(f, c |> block, itr); c)

print_subblocks(io::IO, tree::AbstractContainer, depth, charset, active_levels) = print_subblocks(io, block(tree), depth, charset, active_levels)

include("PutBlock.jl")
include("Control.jl")
include("Repeated.jl")
include("Concentrator.jl")
include("TagBlock.jl")

########## common interfaces are defined here! ##############
for BLOCKTYPE in (:PutBlock, :ControlBlock, :RepeatedBlock, :Concentrator, :Daggered, :CachedBlock, :Scale)
    @eval block(dg::$BLOCKTYPE) = dg.block
    @eval setblock!(pb::$BLOCKTYPE, blk::AbstractBlock) = (pb.block = blk; pb)
end
