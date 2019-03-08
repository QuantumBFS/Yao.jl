# TODO: This file is not included yet.

"""
    SymbolicBlock{T} <: AbstractBlock{T}

Abstract type for symbolic operators.
"""
abstract type SymbolicBlock{T} <: CompositeBlock{T} end

"""
    BinaryOperator{T} <: SymbolicBlock{T}

Abstract type for binary symbolic operators.
"""
abstract type BinaryOperator{T} <: SymbolicBlock{T} end

"""
    ReduceOperator{T, List} <: SymbolicBlock{T}

Abstract type for reduce symbolic operators.
"""
abstract type ReduceOperator{T, List} <: SymbolicBlock{T} end

struct Add{LHS, RHS} <: SymbolicBlock{T}
    lhs::LHS
    rhs::RHS
end

struct Mul{LHS, RHS} <: SymbolicBlock{T}
    lhs::LHS
    rhs::RHS
end

struct Sum{N, T, List <: Tuple} <: ReduceOperator{T, List}
    list::List
end

struct Prod{N, T, List <: Tuple} <: ReduceOperator{T, List}
    list::List
end

# operator overloading
Base.:(-)(x::AbstractBlock{T}) = Mul(Val(-one(T)), x)
Base.:(+)(x::AbstractBlock) = x
Base.:(+)(lhs::AbstractBlock, rhs::AbstractBlock) = Add(lhs, rhs)
Base.:(-)(lhs::AbstractBlock, rhs::AbstractBlock) = Add(lhs, -rhs)
Base.sum(blocks::AbstractBlock...) = Sum(blocks)
Base.prod(blocks::AbstractBlock...) = Prod(blocks)
