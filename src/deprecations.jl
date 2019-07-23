# deprecations
@deprecate iparameters(args...) getiparams(args...)
@deprecate setiparameters!(args...) setiparams!(args...)
@deprecate niparameters(args...) niparams(args...)
@deprecate parameter_type(args...) parameters_eltype(args...)
@deprecate PreserveStyle(args...) PropertyTrait(args...)
@deprecate Sum(args...) Add(args...)
@deprecate Add(blocks::AbstractVector{<:AbstractBlock{N}}) where {N} Add{N}(blocks)
