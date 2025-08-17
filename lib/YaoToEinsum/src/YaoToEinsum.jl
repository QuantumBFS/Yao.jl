module YaoToEinsum

using YaoBlocks, YaoBlocks.YaoArrayRegister, OMEinsum
using YaoBlocks: sparse
using LinearAlgebra
using OMEinsum: writejson, readjson
import OMEinsum: optimize_code

export yao2einsum, DensityMatrixMode, PauliBasisMode, VectorMode
export TensorNetwork, optimize_code, contraction_complexity, contract
export TreeSA, TreeSASlicer, ScoreFunction
export save_tensor_network, load_tensor_network
export viznet

include("Core.jl")
include("circuitmap.jl")
include("densitymatrix.jl")
include("fileio.jl")

"""
    viznet(tn::TensorNetwork; scale=100, filename=nothing, dual_offset=[0.25, 0.25], dangling_offset=[-0.15, -0.15], node_size=7)

Visualize the tensor network with `LuxorGraphPlot`, requires `using LuxorGraphPlot` before using this feature.

# Arguments
- `tn`: the tensor network to visualize.

# Keyword Arguments
- `scale`: the scale of the visualization, which is the average distance between two adjacent nodes, in pixels.
- `filename`: the filename to save the visualization.
- `dual_offset`: the offset of the dual variables.
- `dangling_offset`: the offset of the dangling tensors (those only involve one variables).
- `node_size`: the size of the nodes.

# Returns
- `LuxorGraphPlot.Drawing`: the visualization of the tensor network.
"""
function viznet(args...; kwargs...)
    error("Please load the network visualization extension with `using LuxorGraphPlot`.")
end

@deprecate optimize_code(network::TensorNetwork, optimizer, simplifier; kwargs...) optimize_code(network, optimizer; simplifier, kwargs...)

end
