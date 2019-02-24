using YaoBase
export nqubits,
    datatype,
    isunitary,
    isreflexive,
    ishermitian

export MatrixBlock

"""
    MatrixBlock{N, T} <: AbstractBlock

Abstract type for circuit blocks that have matrix
representation.
"""
abstract type MatrixBlock{N, T} <: AbstractBlock end

function apply!(r::AbstractRegister, b::MatrixBlock)
    r.state .= mat(b) * r
    return r
end

"""
    mat(blk)

Returns the matrix form of given block.
"""
@interface mat(::MatrixBlock)

# YaoBase interface
YaoBase.nqubits(::Type{MT}) where {N, MT <: MatrixBlock{N}} = N
YaoBase.nqubits(x::MatrixBlock{N}) where N = nqubits(typeof(x))
YaoBase.datatype(x::MatrixBlock{N, T}) where {N, T} = T

# properties
for each_property in [:isunitary, :isreflexive, :ishermitian]
    @eval YaoBase.$each_property(x::MatrixBlock) = $each_property(mat(x))
    @eval YaoBase.$each_property(::Type{T}) where T <: MatrixBlock = $each_property(mat(T))
end

function YaoBase.iscommute(op1::MatrixBlock{N}, op2::MatrixBlock{N}) where N
    if length(intersect(occupied_locations(op1), occupied_locations(op2))) == 0
        return true
    else
        return iscommute(mat(op1), mat(op2))
    end
end

include("routines.jl") # contains routines to generate matrices for quantum gates.
include("primitive/primitive.jl")
include("composite/composite.jl")
