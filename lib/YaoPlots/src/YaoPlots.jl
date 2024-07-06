module YaoPlots

using YaoBlocks
using YaoBlocks.DocStringExtensions
using YaoArrayRegister
import Luxor
using Luxor: @layer, Point
using LinearAlgebra: tr
using YaoBlocks

export CircuitStyles, vizcircuit, darktheme!, lighttheme!
export bloch_sphere, BlochStyles
export plot
export LabelBlock, addlabel, LineAnnotation, line_annotation

"""An alias of `vizcircuit`"""
plot(;kwargs...) = x->plot(x;kwargs...)
plot(blk::AbstractBlock; kwargs...) = vizcircuit(blk; kwargs...)

include("helperblock.jl")
include("vizcircuit.jl")
include("3d.jl")
using .Thebes: Point3D, project
include("bloch.jl")

end
