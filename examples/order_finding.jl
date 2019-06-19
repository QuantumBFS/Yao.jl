using Yao, YaoBlocks, BitBasis, LuxurySparse, LinearAlgebra

function YaoBlocks.cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::Adjoint, locs::NTuple{M, Int}) where {C, M}
    YaoBlocks.cunmat(nbit, cbits, cvals, copy(U0), locs)
end

"""x^Nz%N"""
function powermod(x::Int, k::Int, N::Int)
    rem = 1
    for i=1:k
        rem = mod(rem*x, N)
    end
    rem
end

Z_star(N::Int) = filter(i->gcd(i, N)==1, 0:N-1)
Eulerφ(N) = length(Z_star(N))

"""obtain `s` and `r` from `ϕ` that satisfies `|s/r - ϕ| ≦ 1/2r²`"""
continued_fraction(ϕ, niter::Int) = niter==0 ? floor(Int, ϕ) : floor(Int, ϕ) + 1//continued_fraction(1/mod(ϕ, 1), niter-1)
continued_fraction(ϕ::Rational, niter::Int) = niter==0 || ϕ.den==1 ? floor(Int, ϕ) : floor(Int, ϕ) + 1//continued_fraction(1/mod(ϕ, 1), niter-1)

"""
Return `y` that `(x*y)%N == 1`, notice the `(x*y)%N` operations in Z* forms a group.
"""
function mod_inverse(x::Int, N::Int)
    for i=1:N
        (x*i)%N == 1 && return i
    end
    throw(ArgumentError("Can not find the inverse, $x is probably not in Z*($N)!"))
end

is_order(r, x, N) = powermod(x, r, N) == 1

"""get the order, the classical approach."""
function get_order(::Val{:classical}, x::Int, N::Int)
    findfirst(r->is_order(r, x, N), 1:N)
end

function rand_primeto(L)
    while true
        x = rand(2:L-1)
        d = gcd(x, L)
        if d == 1
            return x
        end
    end
end

function shor(L, ver=Val(:quantum); maxiter=100)
    L%2 == 0 && return 2
    # some classical method to accelerate the solution finding
    for i in 1:maxiter
        x = rand_primeto(L)
        r = get_order(ver, x, L)
        # if `x^(r/2)` is non-trivil, go on.
        # Here, we do not condsier `powermod(x, r÷2, L) == 1`, since in this case the order should be `r/2`
        if r%2 == 0 && powermod(x, r÷2, L) != L-1
            f1, f2 = gcd(powermod(x, r÷2, L)-1, L), gcd(powermod(x, r÷2, L)+1, L)
            if f1!=1
                return f1
            elseif f2!=1
                return f2
            else
                error("Algorithm Fail!")
            end
        end
    end
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

Base.adjoint(m::Mod{N}) where N = Mod{N}(mod_inverse(m.a, m.L), m.L)
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

Base.adjoint(m::KMod{N, K}) where {N, K} = KMod{N, K}(mod_inverse(m.a, m.L), m.L)
Yao.print_block(io::IO, m::KMod{N, K}) where {N, K} = print(io, "Mod{$N, $K}: $(m.a)^k*x % $(m.L)")

Yao.isunitary(::KMod) = true
# Yao.ishermitian(::Mod) = true  # this is not true for L = 1.
# Yao.isreflexive(::Mod) = true  # this is not true for L = 1.

estimate_K(nbit::Int, ϵ::Real) = 2*nbit + 1 + ceil(Int,log2(2+1/2ϵ))

using QuAlgorithmZoo: QFTBlock
function order_finding_circuit(x::Int, L::Int; nbit::Int=bit_length(L-1), K::Int=estimate_K(nbit, 0.25))
    N = nbit+K
    chain(N, repeat(N, H, 1:K), KMod{N, K}(x, L), concentrate(N, QFTBlock{K}()', 1:K))
end

function shor(L::Int; nshots=10)
    x = rand_primeto(L)
end

function get_order(::Val{:quantum}, x::Int, L::Int; nshots=10)
    c = order_finding_circuit(x, L)
    n = nqubits_data(c[2])
    K = nqubits_control(c[2])
    reg = join(product_state(n, 1), zero_state(K))

    res = measure(copy(reg) |> c; nshots=nshots)
    reader = bint2_reader(Int, K)
    for r in res
        k, i = reader(r)
        # get s/r
        ϕ = bfloat(k)  #
        ϕ == 0 && continue

        order = order_from_float(ϕ, x, L)
        if order === nothing
            continue
        else
            return order
        end
    end
    return nothing
end

function order_from_float(ϕ, x, L)
    k = 1
    rnum = continued_fraction(ϕ, k)
    while rnum.den < L
        r = rnum.den
        @show r
        if is_order(r, x, L)
            return r
        end
        k += 1
        rnum = continued_fraction(ϕ, k)
    end
    return nothing
end

using Test
function check_Euler_theorem(N::Int)
    Z = Z_star(N)
    Nz = length(Z)   # Eulerφ
    for x in Z
        @test powermod(x,Nz,N) == 1  # the order is a devisor of Eulerφ
    end
end

@testset "Euler" begin
    check_Euler_theorem(150)
end

@testset "Mod" begin
    @test_throws AssertionError Mod{4}(4,10)
    @test_throws AssertionError Mod{2}(3,10)
    m = Mod{4}(3,10)
    @test mat(m) ≈ applymatrix(m)
    @test isunitary(m)
    @test isunitary(mat(m))
    @test m' == Mod{4}(7,10)
end

@testset "KMod" begin
    @test_throws AssertionError KMod{6, 2}(4,10)
    @test_throws AssertionError KMod{4, 2}(3,10)
    m = KMod{6, 2}(3,10)
    @test mat(m) ≈ applymatrix(m)
    @test isunitary(m)
    @test isunitary(mat(m))
    @test m' == KMod{6, 2}(7,10)
end

using Random
@testset "shor_classical" begin
    Random.seed!(129)
    L = 35
    f = shor(L, Val(:classical))
    @test f == 5 || f == 7

    L = 25
    f = shor(L, Val(:classical))
    @test_broken f == 5

    L = 7*11
    f = shor(L, Val(:classical))
    @test f == 7 || f == 11

    L = 14
    f = shor(L, Val(:classical))
    @test f == 2 || f == 7
end

using Random
@testset "shor quantum" begin
    Random.seed!(129)
    L = 15
    f = shor(L, Val(:quantum))
    @test f == 5 || f == 3
end
