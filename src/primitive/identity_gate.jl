export TrivilGate, IdentityGate, igate

abstract type TrivilGate{N} <: PrimitiveBlock{N} end

mat(::Type{T}, d::TrivilGate{N}) where {T,N} = IMatrix{1 << N,T}()
Base.adjoint(g::TrivilGate) = g

"""
    IdentityGate{N} <: TrivilGate{N}

The identity gate.
"""
struct IdentityGate{N} <: TrivilGate{N} end

"""
    igate(n::Int)

The constructor for identity gate.
"""
igate(n::Int) = IdentityGate{n}()
