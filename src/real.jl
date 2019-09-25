using Simplify, MacroTools

struct SymReal <: Real
    term::Term
end

SymReal(name::Symbol) = SymReal(Variable(name))

function Base.show(io::IO, x::SymReal)
    t = x.term
    ex = MacroTools.postwalk(Simplify._show_term, get(t))
    macro_call = Expr(:macrocall, Symbol("@term"), nothing, ex)
    repr = sprint(show, macro_call)[9:end-1]
    print(io, repr)
end

_term(x) = x
_term(x::SymReal) = x.term

function track(f, xs...)
    xs = map(_term, xs)
    t = track_term(f, xs...)
    return SymReal(t)
end

@generated function track_term(f, xs...)
    quote
        convert(Term, Expr(:call, f, xs...))
    end
end

Base.promote_rule(::Type{SymReal}, ::Type{T}) where {T <: Real} = SymReal
Base.convert(::Type{SymReal}, x::Real) = SymReal(@term(x))
Base.convert(::Type{SymReal}, x::SymReal) = x
Base.:(*)(x::SymReal, y::SymReal) = track(*, x, y)


x = SymReal(:x)
y = SymReal(:y)
x * y + 2
ex = 2x * y

ex2 = ex * 3
ex2.term.ex.args[2].args
ex2.term.ex.args[2]|>typeof
ex.term
normalize(ex.term)

dump(ex.term.ex.args)

2 * x

SymReal(@term(exp(2 * )))

convert(SymReal, 2) * x