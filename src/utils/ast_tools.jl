export ASTTools

"""
    ASTTools

Tools for manipulating Julia ASTs. This module provides similar functionality
with MacroTools, but based on MLStyle.
"""
module ASTTools

using MLStyle
export @capture

# capture
function capturing_analysis(expr, out, is_literal)

    @match expr begin
        ::QuoteNode => capturing_analysis(expr.value, out, true)

        if is_literal
        end && Expr(:$, args...) =>

            foreach(x -> capturing_analysis(x, out, false), args)

        if is_literal
        end && Expr(_, args...) =>

            foreach(x -> capturing_analysis(x, out, true), args)


        if is_literal
        end && _ => nothing


        # not literal
        ::Symbol => (push!(out, expr); nothing)

        Expr(:quote, args...) => foreach(x -> capturing_analysis(x, out, true), args)

        :(Do($(args...))) => foreach(args) do arg
            @match arg begin
                Expr(:kw, key::Symbol, value) => begin
                    push!(out, key)
                end
                _ => nothing
            end
        end
        :($a || $b) => let out1 = Set(Symbol[]), out2 = Set(Symbol[])
            capturing_analysis(a, out1, false)
            capturing_analysis(b, out2, false)

            union!(out, intersect(out1, out2))
            nothing
        end
        # type pattern
        Expr(:(::), a, _) => capturing_analysis(a, out, false)
        # dict pattern
        :(Dict($(args...))) => foreach(args) do arg
            @match arg begin
                :($_ => $v) => capturing_analysis(v, out, false)
                _ => nothing
            end
        end
        # app pattern
        :($_($(args...))) => foreach(x -> capturing_analysis(x, out, false), args)
        # other expr
        Expr(_, args...) => foreach(x -> capturing_analysis(x, out, false), args)
        # ref pattern
        Expr(:&, _) ||
        # predicate
        Expr(:function, _...) || Expr(:if, _...) || x => nothing
    end
end

function capture(template)
    syms = Set(Symbol[])
    capturing_analysis(template, syms, true)
    out_expr =
        Expr(:call, Dict, (Expr(:call, =>, QuoteNode(each), each) for each in syms)...)
    arg_sym = gensym()
    let template = Expr(:quote, template)
        quote
            $arg_sym -> $MLStyle.@match $arg_sym begin
                $(template) => $(out_expr)
            end
        end
    end
end

"""
    @capture template
    @capture template expr

Template matching for expressions.

```julia
julia> @capture f(\$x)  :(f(2))
Dict{Symbol,Int64} with 1 entry:
  :x => 2
```
"""
:(@capture)

macro capture(template)
    capture(template) |> esc
end

macro capture(template, ex)
    Expr(:call, capture(template), ex) |> esc
end

end
