# NOTE: we cannot change subblocks of a primitive block
#      since they are primitive, therefore we return themselves
chsubblocks(x::PrimitiveBlock, it) = x
subblocks(x::PrimitiveBlock) = ()
# NOTE: all primitive block should name with postfix Gate
#       and each primitive block should stay in a single
#       file whose name is in lowercase and underscore.
include("const_gate.jl")
include("identity_gate.jl")
include("phase_gate.jl")
include("shift_gate.jl")
include("rotation_gate.jl")
include("time_evolution.jl")
include("general_matrix_gate.jl")
include("measure.jl")

YaoAPI.isdiagonal(p::PrimitiveBlock) = isdiagonal(mat(p))

# Certain blocks, like X block can have faster getindex, but this performance (~2ns) is probably enough!
# Go to each block file to specialize!
function unsafe_getindex(op::PrimitiveBlock{D}, i::Integer, j::Integer) where {D}
    return @inbounds mat(op)[i+1, j+1]
end