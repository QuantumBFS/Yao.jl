# TODO
# compile Mod and KMod to elementary gates.
export Mod, KMod
using YaoBlocks.YaoBase.BitBasis

"""
    mod_inverse(x::Int, N::Int) -> Int

Return `y` that `(x*y)%N == 1`, notice the `(x*y)%N` operations in Z* forms a group and this is the definition of inverse.
"""
function mod_inverse(x::Int, N::Int)
    for i=1:N
        (x*i)%N == 1 && return i
    end
    throw(ArgumentError("Can not find the inverse, $x is probably not in Z*($N)!"))
end

"""
    Mod{N} <: PrimitiveBlock{N}

calculates `mod(a*x, L)`, notice `gcd(a, L)` should be 1.
"""
struct Mod{N} <: PrimitiveBlock{N}
    a::Int
    L::Int
    function Mod{N}(a, L) where N
        @assert gcd(a, L) == 1 && L<=1<<N
        new{N}(a, L)
    end
end

function _apply!(reg::ArrayReg{B}, m::Mod{N}) where {B, N}
    nstate = zero(reg.state)
    for i in basis(reg)
        _i = i >= m.L ? i+1 : mod(i*m.a, m.L)+1
        for j in 1:B
            @inbounds nstate[_i,j] = reg.state[i+1,j]
        end
    end
    reg.state = nstate
    reg
end

function YaoAPI.mat(::Type{T}, m::Mod{N}) where {T, N}
    perm = Vector{Int}(undef, 1<<N)
    for i in basis(N)
        @inbounds perm[i >= m.L ? i+1 : mod(i*m.a, m.L)+1] = i+1
    end
    PermMatrix(perm, ones(T, 1<<N))
end

Base.adjoint(m::Mod{N}) where N = Mod{N}(mod_inverse(m.a, m.L), m.L)
YaoBlocks.print_block(io::IO, m::Mod{N}) where N = print(io, "Mod{$N}: $(m.a)*x % $(m.L)")

YaoAPI.isunitary(::Mod) = true
# LinearAlgebra.ishermitian(::Mod) = true  # this is not true for L = 1.
# YaoAPI.isreflexive(::Mod) = true  # this is not true for L = 1.

"""
    KMod{N, K} <: PrimitiveBlock{N}

The first `K` qubits are exponent `k`, and the rest `N-K` are base `a`,
it calculates `mod(a^k*x, L)`, notice `gcd(a, L)` should be 1.
"""
struct KMod{N, K} <: PrimitiveBlock{N}
    a::Int
    L::Int
    function KMod{N, K}(a, L) where {N, K}
        @assert gcd(a, L) == 1 && L<=1<<(N-K)
        new{N, K}(a, L)
    end
end

nqubits_data(m::KMod{N, K}) where {N, K} = N-K
nqubits_control(m::KMod{N, K}) where {N, K} = K

function bint2_reader(T, k::Int)
    mask = bmask(T, 1:k)
    return b -> (b&mask, b>>k)
end

function _apply!(reg::ArrayReg{B}, m::KMod{N, K}) where {B, N, K}
    nstate = zero(reg.state)

    reader = bint2_reader(Int, K)
    for b in basis(reg)
        k, i = reader(b)
        _i = i >= m.L ? i : mod(i*powermod(m.a, k, m.L), m.L)
        _b = k + _i<<K + 1
        for j in 1:B
            @inbounds nstate[_b,j] = reg.state[b+1,j]
        end
    end
    reg.state = nstate
    reg
end

function YaoAPI.mat(::Type{T}, m::KMod{N, K}) where {T, N, K}
    perm = Vector{Int}(undef, 1<<N)
    reader = bint2_reader(Int, K)
    for b in basis(N)
        k, i = reader(b)
        _i = i >= m.L ? i : mod(i*powermod(m.a, k, m.L), m.L)
        _b = k + _i<<K + 1
        @inbounds perm[_b] = b+1
    end
    PermMatrix(perm, ones(T, 1<<N))
end

Base.adjoint(m::KMod{N, K}) where {N, K} = KMod{N, K}(mod_inverse(m.a, m.L), m.L)
YaoBlocks.print_block(io::IO, m::KMod{N, K}) where {N, K} = print(io, "Mod{$N, $K}: $(m.a)^k*x % $(m.L)")

YaoAPI.isunitary(::KMod) = true
# LinearAlgebra.ishermitian(::Mod) = true  # this is not true for L = 1.
# YaoAPI.isreflexive(::Mod) = true  # this is not true for L = 1.
