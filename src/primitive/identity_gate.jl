export TrivialGate, IdentityGate, igate

abstract type TrivialGate{N} <: PrimitiveBlock{N} end

mat(::Type{T}, d::TrivialGate{N}) where {T,N} = IMatrix{1 << N,T}()
Base.adjoint(g::TrivialGate) = g
occupied_locs(g::TrivialGate) = ()

"""
    IdentityGate{N} <: TrivialGate{N}

The identity gate.
"""
struct IdentityGate{N} <: TrivialGate{N} end

"""
    igate(n::Int)

The constructor for identity gate.
"""
igate(n::Int) = IdentityGate{n}()
