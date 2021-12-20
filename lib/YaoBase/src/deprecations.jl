# deprecations
@deprecate measure_collapseto!(args...; collapseto = 0, kwargs...) measure!(
    ResetTo(collapseto),
    args...;
    kwargs...,
)
@deprecate measure_resetto!(args...; resetto = 0, kwargs...) measure!(
    ResetTo(resetto),
    args...;
    kwargs...,
)
@deprecate measure_remove!(args...; kwargs...) measure!(
    RemoveMeasured(),
    args...;
    kwargs...,
)
