export @interface

macro interface(ex)
    return interfacem(__module__, __source__, ex)
end

function interfacem(__module__::Module, __source__::LineNumberNode, ex::Symbol)
    esc(quote
        export ex
        Core.@__doc__ $(Expr(:function, ex))
    end)
end

function interfacem(__module__::Module, __source__::LineNumberNode, ex::Expr)
    r = handle(ex)

    if r === nothing
        return :(error("expect a function definition or a function call as interface definition"))
    end

    name, args, body = r

    if body === nothing && args === nothing
        return quote
            export $(esc(name))
            Core.@__doc__ $(esc(ex)) = throw(NotImplementedError($(QuoteNode(name))))
        end
    elseif body === nothing
        return quote
            export $(esc(name))
            Core.@__doc__ $(esc(ex)) =
                throw(NotImplementedError($(QuoteNode(name)), tuple($(esc.(args)...))))
            end

    else
        return quote
            export $(esc(name))
            Core.@__doc__ $(esc(ex))
        end
    end
end

handle(ex::Expr, isvalid = false) = handle(Val(ex.head), ex, isvalid)
handle(ex::Symbol, isvalid) =
    isvalid ? (ex, nothing, nothing, nothing) : error("expect a function")
handle(::Val{:where}, ex::Expr, isvalid) = handle(ex.args[1], isvalid)

# valid syntax
function handle(::Val{:(=)}, ex::Expr, isvalid)
    name, args, _ = handle(ex.args[1], isvalid)
    return name, args, ex.args[2]
end

function handle(::Val{:function}, ex::Expr, isvalid)
    name, args, _ = handle(ex.args[1], true)
    if isempty(ex.args[2:end])
        return name, args, nothing
    else
        return name, args, ex.args[2:end]
    end
end

function handle(::Val{:call}, ex::Expr, isvalid)
    args = []
    for each in ex.args[2:end]
        if !(each isa Union{Expr,Symbol})
            return nothing
        end
        if each isa Expr && each.head === :parameters
            continue
        else
            push!(args, name_handle(each))
        end
    end
    return name_handle(ex.args[1]), args, nothing
end

name_handle(x::Symbol) = x
name_handle(x::QuoteNode) = x.value
name_handle(x::Expr) = name_handle(Val(x.head), x)
# type annotation
function name_handle(::Val{:(::)}, x::Expr)
    if length(x.args) == 2
        return name_handle(x.args[1])
    else
        temp = x.args[1]
        x.args[1] = gensym(:x)
        push!(x.args, temp)
        return x.args[1]
    end
end

name_handle(::Val{:(...)}, x::Expr) = Expr(:(...), name_handle(x.args[1]))
name_handle(::Val{:(.)}, x::Expr) = name_handle(x.args[2])
name_handle(::Val{:kw}, x::Expr) = name_handle(x.args[1])
name_handle(::Val, x::Expr) = error("expect a valid variable name got $x")
