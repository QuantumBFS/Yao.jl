export AbstractBlock

using YaoBase
import YaoBase: @interface

"""
    AbstractBlock

Abstract type for quantum circuit blocks.
"""
abstract type AbstractBlock end

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
