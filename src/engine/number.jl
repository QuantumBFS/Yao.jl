export SymNumber
struct SymNumber <: Number
    ex::Term
end

SymNumber(name::Symbol) = SymNumber(Term(Variable(name)))
SymNumber(x::SymReal) = SymNumber(term(x))
SymNumber(x::SymComplex) = SymNumber(term(x))

term(x::SymNumber) = x.ex
Base.show(io::IO, t::SymNumber) = print_term(io, t.ex)

for (M, f, arity) in DiffRules.diffrules()
    op = :($M.$f)

    if arity == 1
        @eval $op(x::SymNumber) = track($op, x)
    elseif arity == 2
        @eval $op(x::SymNumber, y::SymNumber) = track($op, x, y)
    end
end

Base.promote_rule(::Type{<:SymNumber}, ::Type{<:Number}) = SymNumber
Base.promote_rule(::Type{<:SymNumber}, ::Type{<:SymComplex}) = SymNumber

Base.convert(::Type{<:SymNumber}, x::SymNumber) = x
Base.convert(::Type{<:SymNumber}, x::Number) = SymNumber(x)
Base.convert(::Type{<:SymNumber}, x::Irrational) = SymNumber(x)

Base.convert(::Type{<:SymNumber}, x::SymReal) = SymNumber(x)
Base.convert(::Type{<:SymNumber}, x::SymComplex) = SymNumber(x)
