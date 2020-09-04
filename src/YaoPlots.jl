module YaoPlots

export plot

using Compose

plot(;kwargs...) = x->plot(x;kwargs...)

include("vizcircuit.jl")
include("zx_plot.jl")

end
