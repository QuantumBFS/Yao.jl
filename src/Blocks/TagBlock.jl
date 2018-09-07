export TagBlock
abstract type TagBlock{N, T} <: MatrixBlock{N, T} end

for METHOD in (:ishermitian, :isreflexive, :isunitary, :nparameters, :nqubits,
     :parameter_type, :usedbits, :parameters, :datatype, :length, :eltype,
     :blocks, :start, :nactive)
    @eval $METHOD(dg::TagBlock) = $METHOD(parent(dg))
end

==(a::TagBlock, b::TagBlock) = parent(a) == parent(b)
dispatch!(c::TagBlock, params...) = (dispatch!(parent(c), params...); c)
getindex(c::TagBlock, index...) = getindex(parent(c), index...)
setindex!(c::TagBlock, val, index...) = setindex!(parent(c), val, index...)

iterate(c::TagBlock) = iterate(parent(c))
iterate(c::TagBlock, st) = iterate(parent(c), st)

# Print
print_subblocks(io::IO, tree::TagBlock, depth, charset, active_levels) = print_subblocks(io, parent(tree), depth, charset, active_levels)

cache_key(tb::TagBlock) = cache_key(parent(tb))

include("BlockCache.jl")
include("Daggered.jl")
include("Scale.jl")
