export AbstractRegister, ClassicalRegister, register

abstract type AbstractRegister{T, N} end

state(reg::AbstractRegister) = reg.state

mutable struct ClassicalRegister{T <: AbstractVecOrMat, N} <: AbstractRegister{T, N}
    state::T
end

ClassicalRegister(n, statevec::T) where {T <: AbstractVecOrMat} =
    ClassicalRegister{T, n}(statevec)
ClassicalRegister(statevec) =
    ClassicalRegister(Int(log2(size(statevec, 1))), statevec)


import Base: eltype, length, size, getindex, setindex!, copy
# TODO: overload Array interface

copy(reg::ClassicalRegister{T, N}) where {T, N} = ClassicalRegister(N, copy(reg.state))

"""
    register(type, state_type, nqubits) -> Register

factory method for creating a register.
"""
register(::Type{T}, ::Type{S}, n::Integer) where {T, S} = ClassicalRegister(n, zeros(T, 2^n))
register(::Type{S}, n::Integer) where S = register(Complex128, S, n)

register(v::AbstractVecOrMat{T}) where T = ClassicalRegister(v)

export Routine
"""
routines for perparing a state
"""
module Routine

import QuCircuit: ClassicalRegister, register
export GHZ, OOO, Rand

abstract type QuState end
abstract type GHZ <: QuState end
abstract type OOO <: QuState end
abstract type Rand <: QuState end

@inline function register(::Type{T}, ::Type{GHZ}, n::Integer) where T
    state = zeros(T, 2^n)
    state[1] = 1
    state[end] = 1
    state ./= sqrt(2)
    ClassicalRegister(n, state)
end

@inline function register(::Type{T}, ::Type{OOO}, n::Integer) where T
    state = zeros(T, 2^n)
    state[1] = 1
    ClassicalRegister(n, state)    
end

register(::Type{T}, ::Type{Rand}, n::Integer) where T = ClassicalRegister(n, rand(T, 2^n))
end # routine