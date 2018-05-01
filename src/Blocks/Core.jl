"""
    AbstractBlock{N}

abstract type that all block will subtype from. `N` is the number of
qubits.
"""
abstract type AbstractBlock{N} end

# Interface

## Trait
export ninput, noutput, isunitary, iscacheable, cache_type, ispure, get_cache

nqubit(block::AbstractBlock{N}) where N = N
ninput(x::AbstractBlock{N}) where N = N
noutput(x::AbstractBlock{N}) where N = N
isunitary(x::AbstractBlock) = false
iscacheable(x::AbstractBlock) = false
cache_type(x::AbstractBlock) = Cache
ispure(x::AbstractBlock) = false
get_cache(x::AbstractBlock) = []

import Base: copy
# only shallow copy by default
# overload this when block contains parameters
copy(x::AbstractBlock) = x

## Required Methods
function apply! end
function update! end
function cache! end

"""
    PureBlock{N, T} <: AbstractBlock{N}

abstract type that all block with a matrix form will subtype from.
"""
abstract type PureBlock{N, T} <: AbstractBlock{N} end

ispure(block::PureBlock) = true

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
"""
abstract type PrimitiveBlock{N, T} <: PureBlock{N, T} end

iscacheable(block::PrimitiveBlock) = true
isunitary(block::PrimitiveBlock) = true

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

function cache end

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