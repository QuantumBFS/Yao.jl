using Test, YaoBase
using YaoBase: @interface, handle

ex = [
    :(function foo end),
    :(foo(x) = x),
    :(foo(x, y::T) where T),
    :(foo(x, y::T) where T = x)]

@test handle(ex[1]) == (:foo, nothing, nothing)
name, args, body = handle(ex[2])
@test (name, args) == (:foo, [:x])
@test !isnothing(body)

name, args, body = handle(ex[3])
@test (name, args) == (:foo, [:x, :y])
@test isnothing(body)

name, args, body = handle(ex[4])
@test (name, args) == (:foo, [:x, :y])
@test !isnothing(body)

@test_throws ErrorException @interface x + 1
