# This file is shamelessly copied from LegibleLambda.jl
# MasonProtter didn't register this package, what can I
# do?

using MacroTools: postwalk
export @λ, LegibleLambda

"""
    @λ <lambda definition>

Create legible lambdas.

# Example

```julia
julia> @λ(x -> g(x)/3)
(x -> g(x)/3)
```
"""
macro λ(ex)
    if ex.head == :(->)
        ex_cut = ex |> (ex -> postwalk(cutlnn, ex)) |> (ex -> postwalk(cutblock, ex))
        name = (repr(ex_cut)[2:end])
        :(LegibleLambda($name, $(esc(ex))))
    else
        throw("Must be called on a Lambda expression")
    end
end

struct LegibleLambda{F <: Function} <: Function
    name::String
    λ::F
end

(f::LegibleLambda)(args...) = (f.λ)(args...)

cutlnn(x) = x
function cutlnn(ex::Expr)
    Expr(ex.head, ex.args[[!(arg isa LineNumberNode) for arg in ex.args]]...)
end

cutblock(x) = x
function cutblock(ex::Expr)
    if (ex.head == :block) && (length(ex.args)==1)
        ex.args[1]
    else
        ex
    end
end

tupleargs(x::Symbol) = (x,)
function tupleargs(ex::Expr)
    if ex.head == :tuple
        Tuple(ex.args)
    else
        throw("expression must have head `:tuple`")
    end
end


function Base.show(io::IO, f::LegibleLambda)
    print(io, f.name)
end

function Base.show(io::IO, ::MIME"text/plain", f::LegibleLambda)
    print(io, f.name)
end
