export TrivialGate, IdentityGate, igate

abstract type TrivialGate{N,D} <: PrimitiveBlock{N,D} end

mat(::Type{T}, d::TrivialGate{N,D}) where {T,N,D} = IMatrix{D^N,T}()
Base.adjoint(g::TrivialGate) = g
occupied_locs(g::TrivialGate) = ()

"""
    IdentityGate{N,D} <: TrivialGate{N,D}

The identity gate.
"""
struct IdentityGate{N,D} <: TrivialGate{N,D} end

"""
    igate(n::Int; nlevel=2)

The constructor for identity gate.
"""
igate(n::Int; nlevel=2) = IdentityGate{n, nlevel}()
