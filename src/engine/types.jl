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
