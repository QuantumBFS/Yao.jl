export SymComplex

struct SymComplex <: Number
    ex::Term
end

SymComplex(name::Symbol) = SymComplex(Variable(name))
SymComplex(x::SymComplex) = x
SymComplex(x::Number) = SymComplex(Term(x))
SymComplex(x::SymReal) = SymComplex(term(x))
SymComplex(x::SymInteger) = SymComplex(term(x))

function SymComplex(x::Complex)
    re = real(x)
    im = imag(x)
    if iszero(re)
        if isone(im)
            return SymComplex(@term(im))
        else
            SymComplex(@term($im * im))
        end
    else
        SymComplex(@term($re + $im * im))
    end
end

DOMAIN_TYPES[:Complex] = SymComplex

term(x::SymComplex) = x.ex
Base.show(io::IO, t::SymComplex) = print_term(io, t.ex)

for (M, f, arity) in DiffRules.diffrules()
    op = :($M.$f)

    if arity == 1
        @eval $op(x::SymComplex) = track($op, x)
    elseif arity == 2
        @eval $op(x::SymComplex, y::SymComplex) = track($op, x, y)
        @eval $op(x::SymReal, y::Complex{Bool}) = track($op, promote(x, y)...)
        @eval $op(x::Complex{Bool}, y::SymReal) = track($op, promote(x, y)...)
        @eval $op(x::SymReal, y::Complex) = track($op, promote(x, y)...)
        @eval $op(x::Complex, y::SymReal) = track($op, promote(x, y)...)

        # workaround fragile type inference
        @eval Base.promote_op(::typeof($op), ::Type{<:Number}, ::Type{SymComplex}) = SymComplex
        @eval Base.promote_op(::typeof($op), ::Type{SymComplex}, ::Type{<:Number}) = SymComplex
        @eval Base.promote_op(::typeof($op), ::Type{SymComplex}, ::Type{SymComplex}) = SymComplex
    end
end

Base.promote_rule(::Type{<:SymComplex}, ::Type{<:Number}) = SymComplex
Base.promote_rule(::Type{<:SymReal}, ::Type{<:Complex}) = SymComplex

Base.convert(::Type{<:SymComplex}, x::SymComplex) = x
Base.convert(::Type{<:SymComplex}, x::Number) = SymComplex(x)
Base.convert(::Type{<:SymComplex}, x::Complex) = SymComplex(x)
Base.convert(::Type{<:SymComplex}, x::Irrational) = SymComplex(x)

# complex number specialization
Base.adjoint(x::SymComplex) = track(adjoint, x)
Base.real(x::SymComplex) = track(SymReal, real, x)
Base.imag(x::SymComplex) = track(SymReal, imag, x)
Base.conj(x::SymComplex) = track(conj, x)

Base.angle(x::SymReal) = SymReal(0)
Base.angle(x::SymComplex) = track(SymReal, angle, x)
