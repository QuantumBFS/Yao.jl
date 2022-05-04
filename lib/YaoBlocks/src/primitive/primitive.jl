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
function unsafe_getindex(::Type{T}, op::PrimitiveBlock{D}, i::Integer, j::Integer) where {T,D}
    return @inbounds mat(T, op)[i+1, j+1]
end
function unsafe_getcol(::Type{T}, op::PrimitiveBlock{D}, j::DitStr{D}) where {T,D}
    # TODO: check luxury sparse implementation of M[:,j]
    return getcol(mat(T, op), j)
end
function getcol(op::AbstractMatrix, j::DitStr{D,N,TI}) where {D,N,TI}
    res = op[:,buffer(j)+1]
    if res isa SparseVector
        return DitStr{D,N,TI}.(res.nzind .- 1), res.nzval
    else
        return DitStr{D,N,TI}.(0:size(op, 1)-1), res
    end
end
function getcol(op::PermMatrix, j::DitStr{D,N,TI}) where {D,N,TI}
    i = findfirst(==(buffer(j)+1), op.perm)
    return [DitStr{D,N,TI}(i-1)], [op.vals[i]]
end
function getcol(op::Diagonal, j::DitStr{D,N,TI}) where {D,N,TI}
    return [j], [op.diag[buffer(j)+1]]
end
function getcol(::IMatrix{T}, j::DitStr{D,N,TI}) where {D,N,TI,T}
    return [j], [one(T)]
end