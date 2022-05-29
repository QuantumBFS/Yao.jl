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

function print_block(io::IO, x::IdentityGate{2})
    print(io, "igate(", x.n, ")")
end

function print_block(io::IO, x::IdentityGate{D}) where {D}
    print(io, "igate(", x.n, ";nlevel=", D, ")")
end

"""
    igate(n::Int; nlevel=2)

The constructor for [`IdentityGate`](@ref).
Let ``I_d`` be a ``d \\times d`` identity matrix, `igate(n; nlevel=d)` is defined as ``I_d^{\\otimes n}``.

### Examples

```jldoctest; setup=:(using Yao)
julia> igate(2)
igate(2)

julia> igate(2; nlevel=3)
igate(2;nlevel=3)
```
"""
igate(n::Int; nlevel=2) = IdentityGate{nlevel}(n)

function unsafe_getindex(::Type{T}, rg::IdentityGate{D}, i::Integer, j::Integer) where {D,T}
    i==j ? one(T) : zero(T)
end
function unsafe_getcol(::Type{T}, rg::IdentityGate{D}, j::DitStr{D}) where {D,T}
    [j], [one(T)]
end