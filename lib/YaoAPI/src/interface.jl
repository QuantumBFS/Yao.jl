export @interface

macro interface(ex)
    return interfacem(__module__, __source__, ex)
end

function interfacem(__module__::Module, __source__::LineNumberNode, ex::Symbol)
    return esc(
        quote
            export $ex
            Core.@__doc__ $(Expr(:function, ex))
        end,
    )
end
