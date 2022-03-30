using Yao, BitBasis
using Yao.EasyBuild: qft_circuit

module NumberTheory

export Z_star, Eulerφ, continued_fraction, mod_inverse, rand_primeto, factor_a_power_b
export is_order, order_from_float, find_order

"""
    Z_star(N::Int) -> Vector

returns the Z* group elements of `N`, i.e. {x | gcd(x, N) == 1}
"""
Z_star(N::Int) = filter(i->gcd(i, N)==1, 0:N-1)
Eulerφ(N) = length(Z_star(N))

"""
    continued_fraction(ϕ, niter::Int) -> Rational

obtain `s` and `r` from `ϕ` that satisfies `|s/r - ϕ| ≦ 1/2r²`
"""
continued_fraction(ϕ, niter::Int) = niter==0 ? floor(Int, ϕ) : floor(Int, ϕ) + 1//continued_fraction(1/mod(ϕ, 1), niter-1)
continued_fraction(ϕ::Rational, niter::Int) = niter==0 || ϕ.den==1 ? floor(Int, ϕ) : floor(Int, ϕ) + 1//continued_fraction(1/mod(ϕ, 1), niter-1)

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
    is_order(r, x, N) -> Bool

Returns true if `r` is the order of `x`, i.e. `r` satisfies `x^r % N == 1`.
"""
is_order(r, x, N) = powermod(x, r, N) == 1

"""
    find_order(x::Int, N::Int) -> Int

Find the order of `x` by brute force search.
"""
function find_order(x::Int, N::Int)
    findfirst(r->is_order(r, x, N), 1:N)
end

"""
    rand_primeto(N::Int) -> Int

Returns a random number `2 ≦ x < N` that is prime to `N`.
"""
function rand_primeto(N::Int)
    while true
        x = rand(2:N-1)
        d = gcd(x, N)
        if d == 1
            return x
        end
    end
end

"""
    order_from_float(ϕ, x, L) -> Int

Estimate the order of `x` to `L`, `r`, from a floating point number `ϕ ∼ s/r` using the continued fraction method.
"""
function order_from_float(ϕ, x, L)
    k = 1
    rnum = continued_fraction(ϕ, k)
    while rnum.den < L
        r = rnum.den
        if is_order(r, x, L)
            return r
        end
        k += 1
        rnum = continued_fraction(ϕ, k)
    end
    return nothing
end

"""
    factor_a_power_b(N::Int) -> (Int, Int) or nothing

Factorize `N` into the power form `a^b`.
"""
function factor_a_power_b(N::Int)
    y = log2(N)
    for b = 2:ceil(Int, y)
        x = 2^(y/b)
        u1 = floor(Int, x)
        u1^b == N && return (u1, b)
        (u1+1)^b == N && return (u1+1, b)
    end
end

end

"""
    KMod <: PrimitiveBlock{2}

The first `k` qubits are exponent, and the rest `n-k` are base `a`,
it calculates `mod(a^k*x, L)`, notice `gcd(a, L)` should be 1.
"""
struct KMod <: PrimitiveBlock{2}
    n::Int
    k::Int
    a::Int
    L::Int
    function KMod(n, k, a, L)
        @assert gcd(a, L) == 1 && L<=1<<(n-k)
        new(n, k, a, L)
    end
end

Yao.nqudits(m::KMod) = m.n

function bint2_reader(T, k::Int)
    mask = bmask(T, 1:k)
    return b -> (b&mask, b>>k)
end

function _apply!(reg::ArrayReg, m::KMod)
    nstate = zero(reg.state)

    reader = bint2_reader(Int, m.k)
    for b in basis(reg)
        k, i = reader(b)
        _i = i >= m.L ? i : mod(i*powermod(m.a, m.k, m.L), m.L)
        _b = k + _i<<m.k + 1
        for j in 1:YaoArrayRegister._asint(nbatch(reg))
            @inbounds nstate[_b,j] = reg.state[b+1,j]
        end
    end
    reg.state = nstate
    reg
end

function Yao.mat(::Type{T}, m::KMod) where {T}
    perm = Vector{Int}(undef, 1<<m.n)
    reader = bint2_reader(Int, m.k)
    for b in basis(m.n)
        k, i = reader(b)
        _i = i >= m.L ? i : mod(i*powermod(m.a, k, m.L), m.L)
        _b = k + _i<<m.k + 1
        @inbounds perm[_b] = b+1
    end
    YaoBlocks.LuxurySparse.PermMatrix(perm, ones(T, 1<<m.n))
end

Base.adjoint(m::KMod) = KMod(m.n, m.k, mod_inverse(m.a, m.L), m.L)
Yao.print_block(io::IO, m::KMod) = print(io, "Mod: $(m.a)^k*x % $(m.L) (nqubits = $(nqudits(m)), number of control bits = $(m.k))")

using .NumberTheory

function shor(L::Int, ver=Val(:quantum); maxtry=100)
    L%2 == 0 && return 2

    # find short cut solutions like `a^b`
    res = NumberTheory.factor_a_power_b(L)
    res !== nothing && return res[1]

    for i in 1:maxtry
        # step 1
        x = NumberTheory.rand_primeto(L)

        # step 2
        r = get_order(ver, x, L; )
        if r%2 == 0 && powermod(x, r÷2, L) != L-1
            # step 3
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

"""estimate the required size of the output register."""
estimate_ncbit(nbit::Int, ϵ::Real) = 2*nbit + 1 + ceil(Int,log2(2+1/2ϵ))

get_order(::Val{:classical}, x::Int, L::Int; kwargs...) = NumberTheory.find_order(x, L)
function get_order(::Val{:quantum}, x::Int, L::Int; nshots::Int=10,
            nbit::Int=bit_length(L-1), ncbit::Int=estimate_ncbit(nbit, 0.25))
    c = order_finding_circuit(x, L; nbit=nbit, ncbit=ncbit)
    reg = join(product_state(nbit, 1), zero_state(ncbit))

    res = measure(copy(reg) |> c; nshots=nshots)
    for r in res
        # split bit string b into lower bits `k` and higher bits `r`.
        mask = bmask(1:ncbit)
        k,i = r&mask, r>>ncbit
        # get s/r
        ϕ = bfloat(k)  #
        ϕ == 0 && continue

        # order_from_float: given a floating point number,
        # return the closest rational number with bounded number of continued fraction steps.
        order = NumberTheory.order_from_float(ϕ, x, L)
        if order === nothing
            continue
        else
            return order
        end
    end
    return nothing
end

"""
    order_finding_circuit(x::Int, L::Int; nbit::Int=bit_length(L-1), ncbit::Int=estimate_ncbit(nbit, 0.25)) -> AbstractBlock

Returns the circuit for finding the order of `x` to `L`,
feeding input `|1>⊗|0>` will get the resulting quantum register with the desired "phase" information.
"""
function order_finding_circuit(x::Int, L::Int; nbit::Int, ncbit::Int)
    N = nbit+ncbit
    chain(N, repeat(N, H, 1:ncbit), KMod(N, ncbit, x, L),
        subroutine(N, qft_circuit(ncbit)', 1:ncbit))
end

shor(15, Val(:quantum))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

