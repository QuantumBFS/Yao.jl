export simplify
using .Simplify, MacroTools, DiffRules, SpecialFunctions, NaNMath
using .Simplify: _show_term

function print_term(io::IO, t::Term)
    print_term(io, get(t))
end

print_term(io::IO, ex) = print(io, ex)

function print_term(io::IO, ex::Expr)
    ex = MacroTools.postwalk(_show_term, ex)
    macro_call = Expr(:macrocall, Symbol("@term"), nothing, ex)
    repr = sprint(show, macro_call)
    repr = repr[9:prevind(repr, end, 1)]
    print(io, "(", repr, ")")
end

include("types.jl")

simplify(x::Simplify.Term, rules=Simplify.rules()) = Simplify.normalize(x, rules)
simplify(x::T, rules=Simplify.rules()) where {T <: SymbolicType} = T(Simplify.normalize(term(x), rules))

# workaround fragile type inference
NumericType(::Type{SymReal}) = Float64
NumericType(::Type{SymInteger}) = Int
NumericType(::Type{SymComplex}) = ComplexF64
NumericType(::Type{SymNumber}) = Float64
SymType(::Type{<:AbstractFloat}) = SymReal
SymType(::Type{<:Integer}) = SymInteger
SymType(::Type{<:Complex}) = SymComplex
SymType(::Type{<:Number}) = SymNumber

function Base.Broadcast.combine_eltypes(f, args::Tuple{T}) where {T <: SymbolicType}
    SymType(Base.promote_op(f, NumericType(T)))
end

function Base.Broadcast.combine_eltypes(f, args::Tuple{T1, T2}) where {T1 <: SymbolicType, T2 <: SymbolicType}
    SymType(Base.promote_op(f, NumericType(T1), NumericType(T2)))
end

function Base.Broadcast.combine_eltypes(f, args::Tuple{<:AbstractArray{<:T}}) where {T <: SymbolicType}
    SymType(Base.promote_op(f, NumericType(T)))
end

function Base.Broadcast.combine_eltypes(f, args::Tuple{<:AbstractArray{<:T1}, T2}) where {T1 <: SymbolicType, T2 <: SymbolicType}
    SymType(Base.promote_op(f, NumericType(T1), NumericType(T2)))
end

function Base.Broadcast.combine_eltypes(f, args::Tuple{T1, <:AbstractArray{<:T2}}) where {T1 <: SymbolicType, T2 <: SymbolicType}
    SymType(Base.promote_op(f, NumericType(T1), NumericType(T2)))
end

function Base.Broadcast.combine_eltypes(f, args::Tuple{<:AbstractArray{<:T1}, <:AbstractArray{<:T2}}) where {T1 <: SymbolicType, T2 <: SymbolicType}
    SymType(Base.promote_op(f, NumericType(T1), NumericType(T2)))
end

# specialize for typeof(simplify)

Base.Broadcast.combine_eltypes(::typeof(simplify), args::Tuple{T}) where {T <: SymbolicType} = T
Base.Broadcast.combine_eltypes(::typeof(simplify), args::Tuple{T1, T2}) where {T1 <: SymbolicType, T2 <: SymbolicType} = promote_type(T1, T2)
Base.Broadcast.combine_eltypes(::typeof(simplify), args::Tuple{<:AbstractArray{<:T}}) where {T <: SymbolicType} = T
Base.Broadcast.combine_eltypes(::typeof(simplify), args::Tuple{<:AbstractArray{<:T1}, T2}) where {T1 <: SymbolicType, T2 <: SymbolicType} = promote_type(T1, T2)
Base.Broadcast.combine_eltypes(::typeof(simplify), args::Tuple{T1, <:AbstractArray{<:T2}}) where {T1 <: SymbolicType, T2 <: SymbolicType} = promote_type(T1, T2)
Base.Broadcast.combine_eltypes(::typeof(simplify), args::Tuple{<:AbstractArray{<:T1}, <:AbstractArray{<:T2}}) where {T1 <: SymbolicType, T2 <: SymbolicType} = promote_type(T1, T2)
