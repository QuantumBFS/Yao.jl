# deprecations
@deprecate iparameters(args...) getiparams(args...)
@deprecate setiparameters!(args...) setiparams!(args...)
@deprecate niparameters(args...) niparams(args...)
@deprecate parameter_type(args...) parameters_eltype(args...)
@deprecate PreserveStyle(args...) PropertyTrait(args...)
@deprecate Sum(args...) Add(args...)
@deprecate mathgate(f; nbits) mathgate(nbits, f)
@deprecate Concentrator Subroutine
@deprecate concentrate subroutine
@deprecate Add{N}(blocks::Vector{<:AbstractBlock{N,D}}) where {N,D} Add{N,D}(blocks)