export TrivialGate, IdentityGate, igate

abstract type TrivialGate{D} <: PrimitiveBlock{D} end

mat(::Type{T}, d::TrivialGate{D}) where {T,D} = IMatrix{D^nqudits(d),T}()
Base.adjoint(g::TrivialGate) = g
occupied_locs(g::TrivialGate) = ()

"""
    IdentityGate{D} <: TrivialGate{D}

The identity gate.
"""
struct IdentityGate{D} <: TrivialGate{D}
    n::Int
end
nqudits(ig::IdentityGate) = ig.n

"""
    igate(n::Int; nlevel=2)

The constructor for identity gate.
"""
igate(n::Int; nlevel=2) = IdentityGate{nlevel}(n)
