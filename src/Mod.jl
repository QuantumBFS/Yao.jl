# TODO
# compile Mod and KMod to elementary gates.

export Mod, KMod

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

function Yao.apply!(reg::ArrayReg{B}, m::Mod{N}) where {B, N}
    YaoBlocks._check_size(reg, m)
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

function Yao.mat(::Type{T}, m::Mod{N}) where {T, N}
    perm = Vector{Int}(undef, 1<<N)
    for i in basis(N)
        @inbounds perm[i >= m.L ? i+1 : mod(i*m.a, m.L)+1] = i+1
    end
    PermMatrix(perm, ones(T, 1<<N))
end

Base.adjoint(m::Mod{N}) where N = Mod{N}(NumberTheory.mod_inverse(m.a, m.L), m.L)
Yao.print_block(io::IO, m::Mod{N}) where N = print(io, "Mod{$N}: $(m.a)*x % $(m.L)")

Yao.isunitary(::Mod) = true
# Yao.ishermitian(::Mod) = true  # this is not true for L = 1.
# Yao.isreflexive(::Mod) = true  # this is not true for L = 1.

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

function Yao.apply!(reg::ArrayReg{B}, m::KMod{N, K}) where {B, N, K}
    YaoBlocks._check_size(reg, m)
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

function Yao.mat(::Type{T}, m::KMod{N, K}) where {T, N, K}
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

Base.adjoint(m::KMod{N, K}) where {N, K} = KMod{N, K}(NumberTheory.mod_inverse(m.a, m.L), m.L)
Yao.print_block(io::IO, m::KMod{N, K}) where {N, K} = print(io, "Mod{$N, $K}: $(m.a)^k*x % $(m.L)")

Yao.isunitary(::KMod) = true
# Yao.ishermitian(::Mod) = true  # this is not true for L = 1.
# Yao.isreflexive(::Mod) = true  # this is not true for L = 1.
