abstract type AbstractFoo end

mutable struct Foo <: AbstractFoo
    theta
end

dispatch!(x::AbstractFoo, params...) = dispatch!((x, y)->y, x, params...)

function dispatch!(f::Function, x::AbstractFoo, params...)
    println("abstract foo")
    x
end

function dispatch!(f::Function, x::Foo, theta)
    x.theta = theta
    println("foo")
    x
end
