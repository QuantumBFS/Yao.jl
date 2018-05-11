import Base: ismatch
# Size Type
abstract type SizeType end

struct AnySize <: SizeType end
struct GreaterThan{N} <: SizeType end

"""
    ismatch(size, sz) -> Bool

Check whether `sz` matches given `size`.
"""
is_size_match(::Type{T}, sz) where {T <: SizeType} = false
is_size_match(sz, ::Type{T}) where {T <: SizeType} = is_size_match(T, sz)
is_size_match(sza::Int, szb::Int) = sza == szb

is_size_match(::Type{AnySize}, sz::Int) = true
is_size_match(::Type{GreaterThan{N}}, sz::Int) where N = sz > N
is_size_match(::Type{AnySize}, ::Type{T}) where {T <: SizeType} = true

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

import Base: copy, length
# only shallow copy by default
# overload this when block contains parameters
copy(x::AbstractBlock) = x

## Required Methods
export apply!, dispatch!
function apply! end
### do nothing by default
dispatch!(block, params...) = block


# TODO: rename -> MatrixBlock
"""
    PureBlock{N, T} <: AbstractBlock

abstract type that all block with a matrix form will subtype from.
"""
abstract type PureBlock{N, T} <: AbstractBlock end

nqubit(::Type{T}) where {N, T <: PureBlock{N}} = N
ninput(::Type{T}) where {N, T <: PureBlock{N}} = N
noutput(::Type{T}) where {N, T <: PureBlock{N}} = N

ispure(block::PureBlock) = true

import Base: full, sparse, eltype
eltype(block::PureBlock{N, T}) where {N, T} = T
full(block::PureBlock) = full(sparse(block))
# sparse(block)
# copy(block)

# compare methods to enable key-value storage
import Base: hash, ==

### Subtype of PureBlock

"""
    PrimitiveBlock{N, T} <: PureBlock{N, T}

abstract type that all primitive block will subtype from. A primitive block
is a concrete block who can not be decomposed into other blocks. All composite
block can be decomposed into several primitive blocks.

NOTE: subtype for primitive block with parameter should implement `hash` and `==`
method to enable key value cache.
"""
abstract type PrimitiveBlock{N, T} <: PureBlock{N, T} end

isunitary(::Type{T}) where {T <: PrimitiveBlock} = true


"""
    CompositeBlock{N, T} <: PureBlock{N, T}

abstract supertype which composite blocks will inherit from.
"""
abstract type CompositeBlock{N, T} <: PureBlock{N, T} end

# TODO:
# new interface: iterate_blocks

"""
    AbstractMeasure{M} <: AbstractBlock

Abstract block supertype which measurement block will inherit from.
"""
abstract type AbstractMeasure{M} <: AbstractBlock end

nqubit(::Type{T}) where {M, T <: AbstractMeasure{M}} = GreaterThan{M}
ninput(::Type{T}) where {M, T <: AbstractMeasure{M}} = GreaterThan{M}
noutput(::Type{T}) where {M, T <: AbstractMeasure{M}} = AnySize
