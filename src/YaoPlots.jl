module YaoPlots

using Yao
import Luxor

export CircuitStyles, CircuitGrid, circuit_canvas, vizcircuit, darktheme!, lighttheme!
export plot

plot(;kwargs...) = x->plot(x;kwargs...)
plot(blk::AbstractBlock; kwargs...) = vizcircuit(blk; kwargs...)

include("helperblock.jl")
include("vizcircuit.jl")

end
