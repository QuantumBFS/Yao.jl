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
    occupied_locations(blk)

Returns a list of occupied locations of a given block.
"""
@interface occupied_locations(blk::AbstractBlock) = Tuple(1:nqubits(blk))

@interface print_block(io::IO, blk::AbstractBlock) = print(io, blk)
print_block(io::IO, ::MIME"text/plain", blk::AbstractBlock) =
    print_block(io::IO, blk)
