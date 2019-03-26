using Test, YaoBase
using YaoBase: @interface, handle

if VERSION < v"1.1.0"
    isnothing(x) = x === nothing
end

ex = [
    :(function foo end),
    :(foo(x) = x),
    :(foo(x, y::T) where T),
    :(foo(x, y::T) where T = x)]

function check_handle(ex, name, args, body)
    r = handle(ex)
    r_name, r_args, r_body = r

    flag = name == r_name
    if args == true
        flag = flag && !isnothing(r_args)
    else
        flag = flag && (args == r_args)
    end

    if body == true
        return flag && !isnothing(r_body)
    else
        return flag && isnothing(r_body)
    end
end

@test check_handle(ex[1], :foo, nothing, false)
@test check_handle(ex[2], :foo, [:x], true)
@test check_handle(ex[3], :foo, [:x, :y], false)
@test check_handle(ex[4], :foo, [:x, :y], true)

@test_throws ErrorException @interface x + 1

@test check_handle(:(cache_type(::Type{<:AbstractBlock})), :cache_type, true, false)
