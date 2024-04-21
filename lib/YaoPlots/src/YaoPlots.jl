module YaoPlots

using Yao
import Luxor
import Thebes
using Luxor: @layer, Point
using Thebes: Point3D, project
using Yao.YaoBlocks.DocStringExtensions
using LinearAlgebra: tr

export CircuitStyles, CircuitGrid, circuit_canvas, vizcircuit, darktheme!, lighttheme!
export bloch_sphere, BlochStyles
export plot

plot(;kwargs...) = x->plot(x;kwargs...)
plot(blk::AbstractBlock; kwargs...) = vizcircuit(blk; kwargs...)

include("helperblock.jl")
include("vizcircuit.jl")
include("bloch.jl")

end
