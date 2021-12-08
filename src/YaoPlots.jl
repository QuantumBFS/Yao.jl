module YaoPlots

export plot

using Compose

plot(;kwargs...) = x->plot(x;kwargs...)

include("helperblock.jl")
include("vizcircuit.jl")
include("zx_plot.jl")
include("zx_plot_vega.jl")
include("zx_plot_compose.jl")

end
