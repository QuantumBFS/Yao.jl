module YaoPlots

using YaoBlocks
using YaoBlocks.DocStringExtensions
using YaoArrayRegister
import Luxor
import Thebes
using Luxor: @layer, Point
using Thebes: Point3D, project
using LinearAlgebra: tr

export CircuitStyles, vizcircuit, darktheme!, lighttheme!
export bloch_sphere, BlochStyles
export plot

"""An alias of `vizcircuit`"""
plot(;kwargs...) = x->plot(x;kwargs...)
plot(blk::AbstractBlock; kwargs...) = vizcircuit(blk; kwargs...)

include("helperblock.jl")
include("vizcircuit.jl")
include("bloch.jl")

end
