export term, @sym

const DOMAIN_TYPES = Dict()

include("integer.jl")
include("real.jl")
include("complex.jl")
include("number.jl")

const SymbolicType = Union{SymInteger, SymReal, SymComplex, SymNumber}

term(x) = x
get_expr(x) = term(x).ex
function track(f, x::T, xs::T...) where {T <: SymbolicType}
    track(T, f, x, xs...)
end

function track(::Type{T}, f, x, xs...) where {T <: SymbolicType}
    ex = Expr(:call, f, map(get_expr, (x, xs...))...)
    t = Term(ex)
    return T(simplify(t))
end

track(f, xs...) = track(f, promote(xs...)...)

for T in [SymInteger, SymReal, SymComplex, SymNumber]
    @eval Base.:(^)(x::$T, n::Number) = track(^, x, n)
    @eval Base.:(^)(x::$T, n::Integer) = track(^, x, n)
    @eval Base.:(^)(x::$T, n::Real) = track(^, x, n)
    @eval Base.:(^)(x::$T, n::AbstractFloat) = track(^, x, n)
end

macro sym(ex::Expr)
    symm(ex)
end

function symm(ex::Expr)
    if ex.head === :call
        ts, xs = parse_sym(ex)
    else
        ex.head === :tuple || throw(Meta.ParseError("expect a tuple, e.g @sym x, y, z"))

        xs = Expr(:tuple)
        ts = Expr(:tuple)
        for each in ex.args
            name, e = parse_sym(each)
            push!(xs.args, e)
            push!(ts.args, name)
        end    
    end
    return :($(esc(ts)) = $xs)
end

function parse_sym(name::Symbol)
    name, :(SymNumber($(Meta.quot(name))))
end

function parse_sym(ex::Expr)
    ex.head === :call || throw(Meta.ParseError("expect sym in domain, got $ex"))
    if ex.args[1] === :in # domain
        name, domain = ex.args[2], ex.args[3]
        if haskey(DOMAIN_TYPES, domain)
            T = DOMAIN_TYPES[domain]
            return name, :($T($(Meta.quot(name))))
        else
            throw(Meta.ParseError("unsupported domain $(domain)"))
        end
    else
        throw(Meta.ParseError("invalid syntax $ex"))
    end
end


using .Simplify.SpecialSets
using .Simplify: set_context!, Context, Associative, Commutative

# we only consider them as scalars numbers here
set_context!(Context([
    Associative.([
        +,
        *,
        &,
        |,
        ⊻,
    ]);
    Commutative.([
        +,
        *,
        &,
        |,
        ⊻,
    ]);
    Closure(+, TypeSet(Number))
    Closure(+, TypeSet(Int))
    Closure(-, TypeSet(Number))
    Closure(-, TypeSet(Int))
    Closure(*, TypeSet(Number))
    Closure(*, TypeSet(Int))
    Signature(inv, [TypeSet(Number)], TypeSet(Number))
    Signature(/, [TypeSet(Number), TypeSet(Number)], TypeSet(Float64))
    Signature(^, [Positive, TypeSet(Number)], Positive)
    Signature(^, [Zero, TypeSet(Number)], Set([0, 1]))
    Signature(^, [TypeSet(Number), Even], Nonnegative)
    Signature(^, [TypeSet(Real), TypeSet(Real)], TypeSet(Real))
    Signature(^, [TypeSet(Number), TypeSet(Number)], TypeSet(Number))
    Signature(abs, [TypeSet(Number)], Nonnegative)
    Signature(sqrt, [TypeSet(Real)], Nonnegative)
    Signature(sin, [TypeSet(Real)], GreaterThan{Number}(-1, true) ∩ LessThan{Number}(1, true))
    Signature(cos, [TypeSet(Real)], GreaterThan{Number}(-1, true) ∩ LessThan{Number}(1, true))
    Signature(tan, [TypeSet(Number)], TypeSet(Number))
    Signature(log, [TypeSet(Number)], TypeSet(Float64))
    Signature(diff, [TypeSet(Number), TypeSet(Number)], TypeSet(Number))  # FIXME
    Closure(&, TypeSet(Bool))
    Closure(|, TypeSet(Bool))
    Signature(!, [TypeSet(Bool)], TypeSet(Bool))
]))
