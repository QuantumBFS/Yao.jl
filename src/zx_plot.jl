using ZXCalculus

function plot(zxd::AbstractZXDiagram; backend = :vega, kwargs...)
    backend === :vega && return plot_vega(zxd; kwargs...)
    backend === :compose && return plot_compose(zxd; kwargs...)
end