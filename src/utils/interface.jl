using MacroTools

macro interface(ex::Expr)
    if is_function_call(ex)
        return define_abstract_api(ex, get_raw_name(eatwhere(ex).args[1]))
    else
        try
            def = splitdef(ex)
            return export_api(ex, get_raw_name(def[:name]))
        catch e
            if !(e isa AssertionError)
                rethrow(e)
            end
        end
    end
    throw(Meta.ParseError("Expect a function call or function definition"))
end

get_raw_name(ex::Expr) = (@capture(ex, m_.api_); api)
get_raw_name(ex::Symbol) = ex

function eatwhere(ex::Expr)
    if ex.head == :where
        return ex.args[1]
    else
        return ex
    end
end

is_function_call(ex::Expr) = eatwhere(ex).head == :call

function export_api(ex, api)
    api_name = QuoteNode(api)
    return quote
        export $(api)
        Core.@__doc__ $(esc(ex))
    end
end

function define_abstract_api(ex::Expr, api)
    api_name = QuoteNode(api)
    return quote
        export $(api)
        Core.@__doc__ $(esc(ex)) = throw(NotImplementedError($(api_name)))
    end
end
