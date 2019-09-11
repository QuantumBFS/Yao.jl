export @sym

struct SymRealScalar <: Real
    name::Symbol
end

struct SymGeneralScalar <: Number
    name::Symbol
end

struct SymRealExpr{F, Args <: Tuple} <: Real
    head::F
    args::Args
end

struct SymGeneralScalarExpr{F, Args <: Tuple} <: Number
    head::F
    args::Args
end

const SymReal = Union{SymRealScalar, SymRealExpr}
const SymNumber = Union{SymGeneralScalar, SymGeneralScalarExpr}
const SymScalarExpr{F, Args} = Union{SymRealExpr{F, Args}, SymGeneralScalarExpr{F, Args}}
const SymScalar = Union{SymReal, SymNumber}
const SymScalarLeaf = Union{SymRealScalar, SymGeneralScalar}

isleaf(::SymScalarLeaf) = true
IsSymbolic(::SymScalar) = Symbolic()

function symm(ex::Symbol)
    return :($(esc(ex)) = SymGeneralScalar($(QuoteNode(ex))); nothing)
end

function symm(ex::Expr)
    if ex.head === :call && ex.args[1] === :in
        ex.args[2] isa Symbol || throw(Meta.ParseError("expect a symbol got $(ex.args[2])"))
        ex.args[3] === :Real && 
            return :($(esc(ex.args[2])) = SymRealScalar($(QuoteNode(ex.args[2]))); nothing)

    elseif ex.head === :tuple
        return Expr(:block, map(symm, ex.args)..., nothing)
    end

    throw(Meta.ParseError("Invalid expression: $ex"))
end

macro sym(ex)
    symm(ex)
end

Base.show(io::IO, x::SymScalarLeaf) = print(io, x.name)

# prefix by default
function Base.show(io::IO, ex::SymScalarExpr)
    print(io, ex.head, "(")
    for k in eachindex(ex.args)
        print(io, ex.args[k])
        if k != lastindex(ex.args)
            print(io, ", ")
        end
    end
    print(io, ")")
end

# infix
for op in [:+, :*, :/, :-]
    @eval function Base.show(io::IO, ex::SymScalarExpr{typeof($op)})
        for k in eachindex(ex.args)
            print(io, ex.args[k])
            if k != lastindex(ex.args)
                print(io, " ", $op, " ")
            end
        end
    end
end


Base.show(io::IO, ex::SymScalarExpr{typeof(*), Tuple{A, B}}) where {A<:Number, B<:Number} =
    print_scalar(io, ex, IsSymbolic.(ex.args)...)


function print_scalar(io::IO, ex::SymScalarExpr{typeof(*)}, ::Numeric, ::Symbolic)
    if isleaf(ex.args[2])
        print(io, ex.args[1], ex.args[2])
    else
        print(io, ex.args[1], "(", ex.args[2], ")")
    end
end

function print_scalar(io::IO, ex::SymScalarExpr{typeof(*)}, ::Symbolic, ::Numeric)
    if isleaf(ex.args[1])
        print(io, ex.args[2], ex.args[1])
    else
        print(io, ex.args[2], "(", ex.args[1], ")")
    end
end


function print_scalar(io::IO, ex::SymScalarExpr{typeof(*)}, ::Symbolic, ::Symbolic)
    if isleaf(ex.args[1]) && isleaf(ex.args[2])
        print(io, ex.args[1], ex.args[2])
    elseif isleaf(ex.args[2])
        print(io, "(", ex.args[1], ")", ex.args[2])
    elseif isleaf(ex.args[1])
        print(io, ex.args[1], "(", ex.args[2], ")")
    else
        print(io, "(", ex.args[1], ")(", ex.args[2], ")")
    end
end

Base.show(io::IO, ex::SymScalarExpr{typeof(/), Tuple{A, B}}) where {A<:Number, B<:Number} =
    print_scalar(io, ex, IsSymbolic.(ex.args)...)

function print_scalar(io::IO, ex::SymScalarExpr{typeof(/)}, ::Numeric, ::Symbolic)
    if isleaf(ex.args[2])
        print(io, ex.args[1], "/", ex.args[2])
    else
        print(io, ex.args[1], "/(", ex.args[2], ")")
    end
end

function print_scalar(io::IO, ex::SymScalarExpr{typeof(/)}, ::Symbolic, ::Symbolic)
    if isleaf(ex.args[1]) && isleaf(ex.args[2])
        print(io, ex.args[1], ex.args[2])
    elseif isleaf(ex.args[2])
        print(io, "(", ex.args[1], ")/", ex.args[2])
    elseif isleaf(ex.args[1])
        print(io, ex.args[1], "/(", ex.args[2], ")")
    else
        print(io, "(", ex.args[1], ")/(", ex.args[2], ")")
    end
end

# binary operators
for op in [:+, :-, :*, :/]
    @eval Base.$op(x::SymScalar, y::SymScalar) = SymGeneralScalarExpr($op, (x, y))
    @eval Base.$op(x::SymScalar, y::Number) = SymGeneralScalarExpr($op, (x, y))
    @eval Base.$op(x::Number, y::SymScalar) = SymGeneralScalarExpr($op, (x, y))
    # infer real
    @eval Base.$op(x::SymReal, y::SymReal) = SymRealExpr($op, (x, y))
    @eval Base.$op(x::Real, y::SymReal) = SymRealExpr($op, (x, y))
    @eval Base.$op(x::SymReal, y::Real) = SymRealExpr($op, (x, y))
end

# unary
Base.:(+)(x::SymScalar) = x
Base.:(-)(x::SymScalar) = SymGeneralScalarExpr(-, (x, ))
Base.:(-)(x::SymReal) = SymRealExpr(-, (x, ))

Base.show(io::IO, x::SymScalarExpr{typeof(-), Tuple{<:SymScalar}}) = print(io, "-", x.args[1])
