using Compat
import Yao.CacheServers: iscached, update!, pull, clear!

struct Scalar{T}
    val::T
end

struct Grad{T}
    val::T
end

struct Param{T}
    val::T
end

mutable struct Variable{T}
    val::T
    grad::T
end

Variable(val::T) where T = Variable(val, T(0))

iscached(val) = true

function update!(var::Variable{T}, grad::Grad{T}) where {T <: Number}
    var.grad = grad.val
    var
end

function update!(var::Variable{T}, param::Param{T}) where {T <: Number}
    var.val = param.val
    var
end

pull(var::Variable, ::Type{Grad}) = var.grad
pull(var::Variable, ::Type{Param}) = var.val
clear!(var::Variable{<:Number}) = var.grad = 0
