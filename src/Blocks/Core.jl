"""
    AbstractBlock{N}

abstract type that all block will subtype from. `N` is the number of
qubits.
"""
abstract type AbstractBlock{N} end

# Interface

## Trait
export nqubit, ninput, noutput, isunitary, iscacheable, cache_type, ispure, get_cache

nqubit(::Type{T}) where {N, T <: AbstractBlock{N}} = N
ninput(::Type{T}) where {N, T <: AbstractBlock{N}} = N
noutput(::Type{T}) where {N, T <: AbstractBlock{N}} = N
isunitary(::Type{T}) where {T <: AbstractBlock} = false
iscacheable(::Type{T}) where {T <: AbstractBlock} = false
cache_type(::Type{T}) where {T <: AbstractBlock} = Cache
ispure(::Type{T}) where {T <: AbstractBlock} = false

for NAME in [:nqubit, :ninput, :noutput, :isunitary, :iscacheable, :cache_type, :ispure]
    @eval begin
        $NAME(block::AbstractBlock) = $NAME(typeof(block))
    end
end

get_cache(x::AbstractBlock) = []

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
    PureBlock{N, T} <: AbstractBlock{N}

abstract type that all block with a matrix form will subtype from.
"""
abstract type PureBlock{N, T} <: AbstractBlock{N} end

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

export level
level(::Type{T}) where {N, L, T<:AbstractCache{N, L}} = L
level(block::AbstractCache) = level(typeof(block))

function cache end
function cache_method end

"""
    AbstractMeasure{N, M} <: AbstractBlock{N}

Abstract block supertype which measurement block will inherit from.
"""
abstract type AbstractMeasure{N, M} <: AbstractBlock{N} end


struct Concentrator{N, M} <: AbstractBlock{N}
    line_orders::NTuple{M, Int}
end

Concentrator(nqubit::Int, orders::NTuple{M, Int}) where M = Concentrator{nqubit, M}(orders)

noutput(x::Concentrator{N, M}) where {N, M} = M
line_orders(x::Concentrator) = x.line_orders

export focus
focus(nqubit, orders::Int...) = Concentrator(nqubit, orders)
focus(nqubit, orders::NTuple) = Concentrator(nqubit, orders)

apply!(reg::Register{N}, block::Concentrator{N}) where N = focus!(reg, line_orders(block))

struct Sequence{N} <: AbstractBlock{N}
    list::Vector
end

sequence(blocks::AbstractBlock{N}...) where N = Sequence{N}([blocks...])

function apply!(reg::Register{N}, block::Sequence{N}) where N
    for each in block.list
        apply!(reg, each)
    end
    reg
end
