export SymReal

struct SymReal <: Real
    ex::Term
end

SymReal(name::Symbol) = SymReal(Term(Variable(name)))
SymReal(x::SymReal) = x
DOMAIN_TYPES[:Real] = SymReal

term(x::SymReal) = x.ex
Base.show(io::IO, t::SymReal) = print_term(io, t.ex)

for (M, f, arity) in DiffRules.diffrules()
    op = :($M.$f)

    if arity == 1
        @eval $op(x::SymReal) = track($op, x)
    elseif arity == 2
        @eval $op(x::SymReal, y::SymReal) = track($op, x, y)

        # workaround fragile type inference
        @eval Base.promote_op(::typeof($op), ::Type{<:Real}, ::Type{SymReal}) = SymReal
        @eval Base.promote_op(::typeof($op), ::Type{SymReal}, ::Type{<:Real}) = SymReal
        @eval Base.promote_op(::typeof($op), ::Type{SymReal}, ::Type{SymReal}) = SymReal
    end
end

Base.promote_rule(::Type{<:SymReal}, ::Type{<:Real}) = SymReal
Base.convert(::Type{<:SymReal}, x::SymReal) = x
Base.convert(::Type{<:SymReal}, x::Real) = SymReal(x)
Base.convert(::Type{<:SymReal}, x::Irrational) = SymReal(x)
