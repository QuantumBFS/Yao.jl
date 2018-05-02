"""
    AbstractBlock

abstract type that all block will subtype from. `N` is the number of
qubits.
"""
abstract type AbstractBlock end

# Interface

import Base: ==
struct AnySize end
==(lhs::AnySize, rhs::AnySize) = true
==(lhs::AnySize, rhs) = true
==(lhs, rhs::AnySize) = true

## Trait
export nqubit, ninput, noutput, isunitary, iscacheable, cache_type, ispure, get_cache

nqubit(::Type{T}) where {T <: AbstractBlock} = AnySize()
ninput(::Type{T}) where {T <: AbstractBlock} = AnySize()
noutput(::Type{T}) where {T <: AbstractBlock} = AnySize()
isunitary(::Type{T}) where {T <: AbstractBlock} = false
iscacheable(::Type{T}) where {T <: AbstractBlock} = false
cache_type(::Type{T}) where {T <: AbstractBlock} = Cache
ispure(::Type{T}) where {T <: AbstractBlock} = false

for NAME in [:nqubit, :ninput, :noutput, :isunitary, :iscacheable, :cache_type, :ispure]
    @eval begin
        $NAME(block::AbstractBlock) = $NAME(typeof(block))
    end
end

get_cache(x::AbstractBlock) = nothing

import Base: copy, length
# only shallow copy by default
# overload this when block contains parameters
copy(x::AbstractBlock) = x

## Required Methods
export apply!, update!, cache!
function apply! end
### do nothing by default
update!(block, params...) = block
cache!(block; level=1, force=false, method=sparse) = block

"""
    PureBlock{N, T} <: AbstractBlock

abstract type that all block with a matrix form will subtype from.
"""
abstract type PureBlock{N, T} <: AbstractBlock end

nqubit(::Type{T}) where {N, T <: PureBlock{N}} = N
ninput(::Type{T}) where {N, T <: PureBlock{N}} = N
noutput(::Type{T}) where {N, T <: PureBlock{N}} = N

ispure(block::PureBlock) = true
iscacheable(block::PureBlock) = true

import Base: full, sparse, eltype
eltype(block::PureBlock{N, T}) where {N, T} = T
# full(block)
# sparse(block)
# copy(block)

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

"""
    AbstractCache{N, L, T} <: PureBlock{N, T}

abstract supertype which cache blocks will inherit from.
"""
abstract type AbstractCache{N, L, T} <: PureBlock{N, T} end

export cache_level
cache_level(::Type{T}) where {N, L, T<:AbstractCache{N, L}} = L
cache_level(block::AbstractCache) = cache_level(typeof(block))

function cache end
function cache_method end

# compare methods to enable key-value storage
import Base: hash, ==


"""
    AbstractMeasure{N, M} <: AbstractBlock

Abstract block supertype which measurement block will inherit from.
"""
abstract type AbstractMeasure{N, M} <: AbstractBlock end

nqubit(::Type{T}) where {N, T <: AbstractMeasure{N}} = N
ninput(::Type{T}) where {N, T <: AbstractMeasure{N}} = N
noutput(::Type{T}) where {N, M, T <: AbstractMeasure{N, M}} = N - M

struct Concentrator{T <: Union{Int, Tuple}} <: AbstractBlock
    address::T
end

Concentrator(orders...) = Concentrator(orders)

eltype(::Concentrator) = Bool
isunitary(x::Concentrator) = true
noutput(x::Concentrator) = length(x.address)
address(x::Concentrator) = x.address

export focus
focus(orders...) = Concentrator(orders...)
apply!(reg::Register, block::Concentrator) = focus!(reg, address(block)...)

struct Sequence{T <: Tuple} <: AbstractBlock
    list::T
end

sequence(blocks...) = Sequence(blocks)

function apply!(reg::Register, block::Sequence)
    for each in block.list
        apply!(reg, each)
    end
    reg
end
