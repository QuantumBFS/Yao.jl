export AbstractBlock

"""
    AbstractBlock

abstract type that all block will subtype from. `N` is the number of
qubits.
"""
abstract type AbstractBlock end

# This is something will be fixed in 1.x
# see https://github.com/JuliaLang/julia/issues/14919
# We will define a call for each concrete type
# (block::T)(reg::Register) where {T <: AbstractBlock} = apply!(reg, block)

# Interface
## Trait
export nqubit, ninput, noutput, isunitary, ispure

nqubit(::Type{T}) where {T <: AbstractBlock} = AnySize
ninput(::Type{T}) where {T <: AbstractBlock} = AnySize
noutput(::Type{T}) where {T <: AbstractBlock} = AnySize
isunitary(::Type{T}) where {T <: AbstractBlock} = false
ispure(::Type{T}) where {T <: AbstractBlock} = false
isreflexive(::Type{T}) where {T <: AbstractBlock} = false
isunitary_hermitian(::Type{T}) where {T <: AbstractBlock} = false

import Base: ishermitian
ishermitian(::Type{T}) where {T <: AbstractBlock} = false

for NAME in [:nqubit, :ninput, :noutput, :isunitary, :ispure, :isreflexive, :ishermitian]
    @eval begin
        $NAME(block::AbstractBlock) = $NAME(typeof(block))
    end
end

import Base: copy
# only shallow copy by default
# overload this when block contains parameters
copy(x::AbstractBlock) = x

## Required Methods
export apply!, dispatch!

"""
    apply!(reg, block, [signal])

apply a `block` to a register `reg` with or without a cache signal.
"""
function apply! end

### do nothing by default
dispatch!(block, params...) = block
