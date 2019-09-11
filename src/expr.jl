struct SymExpr{OpType}
    head::OpType
    args::Vector
end

SymExpr(f, xs...) = SymExpr(f, collect(xs))

function mapchildren(f, ex::SymExpr)
    SymExpr(ex.head, map(f, ex.args))
end

Base.adjoint(ex::SymExpr{typeof(+)}) = mapchildren(adjoint, ex)

# prefix by default
function Base.show(io::IO, ex::SymExpr)
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
for op in [:+, :/, :*, :-]
    @eval function Base.show(io::IO, ex::SymExpr{typeof($op)})
        for k in eachindex(ex.args)
            print(io, ex.args[k])
            if k != lastindex(ex.args)
                print(io, " ", $op, " ")
            end
        end
    end
end

Base.:(==)(x::SymExpr, y::SymExpr) = false

function Base.:(==)(x::SymExpr{F}, y::SymExpr{F}) where F
    for (x, y) in zip(x.args, y.args)
        x == y || return false
    end
    return true
end

struct Scale{T, Ex}
    a::T
    ex::Ex
end

function Base.show(io::IO, x::Scale{T}) where T
    if x.a ≈ -one(T)
        print(io, "-", x.ex)
    elseif isleaf(x.ex)
        print(io, x.a, x.ex)
    else
        print(io, x.a, "(", x.ex, ")")
    end
end

struct Dot{LHS, RHS}
    lhs::LHS
    rhs::RHS
end
