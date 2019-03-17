export AbstractBlock

using YaoBase
import YaoBase: @interface

"""
    AbstractBlock

Abstract type for quantum circuit blocks.
"""
abstract type AbstractBlock{N, T} end

"""
    apply!(register, block)

Apply a block (of quantum circuit) to a quantum register.
"""
@interface apply!(::AbstractRegister, ::AbstractBlock)

"""
    |>(register, blk)

Pipe operator for quantum circuits.

# Example

```julia
julia> ArrayReg(bit"0") |> X |> Y
```

!!! warning

    `|>` is equivalent to [`apply!`](@ref), which means it has side effects. You
    need to copy original register, if you do not want to change it in-place.
"""
Base.:(|>)(r::AbstractRegister, blk::AbstractBlock) = apply!(r, blk)

"""
    OccupiedLocations(x)

Return an iterator of occupied locations of `x`.
"""
@interface OccupiedLocations(x::AbstractBlock) = 1:nqubits(x)

"""
    applymatrix(g::AbstractBlock) -> Matrix

Transform the apply! function of specific block to dense matrix.
"""
@interface applymatrix(g::AbstractBlock) = linop2dense(r->statevec(apply!(ArrayReg(r), g)), nqubits(g))

@interface print_block(io::IO, blk::AbstractBlock) = print_block(io, MIME("text/plain"), blk)
print_block(blk::AbstractBlock) = print_block(stdout, blk)
print_block(io::IO, ::MIME"text/plain", blk::AbstractBlock) = summary(io, blk)

# return itself by default
Base.copy(x::AbstractBlock) = x


function apply!(r::AbstractRegister, b::AbstractBlock)
    r.state .= mat(b) * r
    return r
end

"""
    mat(blk)

Returns the matrix form of given block.
"""
@interface mat(::AbstractBlock)

# YaoBase interface
YaoBase.nqubits(::Type{<:AbstractBlock{N}}) where N = N
YaoBase.nqubits(x::AbstractBlock{N}) where N = nqubits(typeof(x))
YaoBase.datatype(x::AbstractBlock{N, T}) where {N, T} = T
YaoBase.datatype(::Type{<:AbstractBlock{N, T}}) where {N, T} = T

# properties
for each_property in [:isunitary, :isreflexive, :ishermitian]
    @eval YaoBase.$each_property(x::AbstractBlock) = $each_property(mat(x))
    @eval YaoBase.$each_property(::Type{T}) where T <: AbstractBlock = $each_property(mat(T))
end

function iscommute_fallback(op1::AbstractBlock{N}, op2::AbstractBlock{N}) where N
    if length(intersect(occupied_locations(op1), occupied_locations(op2))) == 0
        return true
    else
        return iscommute(mat(op1), mat(op2))
    end
end

YaoBase.iscommute(op1::AbstractBlock{N}, op2::AbstractBlock{N}) where N =
    iscommute_fallback(op1, op2)
