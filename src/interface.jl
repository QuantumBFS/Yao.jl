export @interface

"""
    INTERFACES::Vector{Symbol}

constant to store all the interfaces symbol.
"""
const INTERFACES = Symbol[]

macro interface(ex)
    return interfacem(__module__, __source__, ex)
end

function interfacem(__module__::Module, __source__::LineNumberNode, ex::Symbol)
    esc(quote
        export $ex
        push!($INTERFACES, $ex)
        Core.@__doc__ $(Expr(:function, ex))
    end)
end
