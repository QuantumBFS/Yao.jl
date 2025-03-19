# # [Shor's Algorithm](@id Shor)

# ## References
# * [Neilsen](https://aapt.scitation.org/doi/abs/10.1119/1.1463744?journalCode=ajp)
# * [An Insightful Blog](https://algassert.com/post/1718)

# The main program of a Shor's algorithm can be summarized in several lines of code.
# For the theory part, please refer to the reference materials above.
# It factorizes an integer `L`, and returns one of the factors.
using Yao, BitBasis
using Yao.EasyBuild: qft_circuit

# ## Number theory basic
# Before entering the main program, let us define some useful functions in number theory.

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
continued_fraction(ϕ, niter::Int) = niter==0 || isinteger(ϕ) ? floor(Int, ϕ) : floor(Int, ϕ) + 1//continued_fraction(1/mod(ϕ, 1), niter-1)
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
    while rnum.den < L && k < 100
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

# ## A quantum function to compute `mod`
# Before introducing the main program, let us customize a block for computing the classical function `mod`.
# In a more practical setup, it should be compiled to basic quantum gates. Here we just hack this function for simplicity.

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

function Yao.unsafe_apply!(reg::AbstractArrayReg, m::KMod)
    nstate = zero(reg.state)

    reader = bint2_reader(Int, m.k)
    for b in 0:1<<m.n-1
        k, i = reader(b)
        _i = i >= m.L ? i : mod(i*powermod(m.a, k, m.L), m.L)
        _b = k + _i<<m.k + 1
        for j in 1:size(nstate,2)
            @inbounds nstate[_b,j] = reg.state[b+1,j]
        end
    end
    reg.state .= nstate
    reg
end

function Yao.mat(::Type{T}, m::KMod) where {T}
    perm = Vector{Int}(undef, 1<<m.n)
    reader = bint2_reader(Int, m.k)
    for b in 0:1<<m.n-1
        k, i = reader(b)
        _i = i >= m.L ? i : mod(i*powermod(m.a, k, m.L), m.L)
        _b = k + _i<<m.k + 1
        @inbounds perm[_b] = b+1
    end
    YaoBlocks.LuxurySparse.PermMatrix(perm, ones(T, 1<<m.n))
end

Base.adjoint(m::KMod) = KMod(m.n, m.k, mod_inverse(m.a, m.L), m.L)
Yao.print_block(io::IO, m::KMod) = print(io, "Mod: $(m.a)^k*x % $(m.L) (nqubits = $(nqudits(m)), number of control bits = $(m.k))")

# ## Main Program
# Here, the input `ver` can be either `Val(:quantum)` or `Val(:classical)`,
# where the classical version is for comparison.
using .NumberTheory

function shor(L::Int, ver=Val(:quantum); maxtry=100)
    L%2 == 0 && return 2

    ## find short cut solutions like `a^b`
    res = NumberTheory.factor_a_power_b(L)
    res !== nothing && return res[1]

    for _ = 1:maxtry
        ## step 1
        x = NumberTheory.rand_primeto(L)

        ## step 2
        r = get_order(ver, x, L; )
        if r%2 == 0 && powermod(x, r÷2, L) != L-1
            ## step 3
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

# Except some shortcuts, in each try, the main program can be summarized in several steps
# 1. randomly pick a number that prime to the input numebr `L`, i.e. `gcd(x, L) = 1`.
# The complexity of this algorithm is polynomial.
# 2. get the order `x`, i.e. finding a number `r` that satisfies `mod(x^r, L) = 1`.
# If `r` is even and `x^(r÷2)` is non-trivial, go on, otherwise start another try.
# Here, trivial means equal to `L-1 (mod L)`.
# 3. According to Theorem 5.2 in Neilsen book,
# one of `gcd(x^(r÷2)-1, L)` and `gcd(x^(r÷2)+1, L)` must be a non-trivial (`!=1`) factor of `L`.
# Notice `powermod(x, r÷2, L)` must be `-1` rather than `1`,
# otherwise the order should be `r/2` according to definition.

# The only difference between classical and quantum version is the order finding algorithm.

# ## Order Finding
# We provided a classical order finding algorithm in `NumberTheory`,
# here we focus on the quantum version.
# The algorithm is consisted
# 1. run the circuit to get a bitstring,
# 2. interpret this bitstring in output register as a rational number `s/r`.
# To achieve this, we first interpret it as a floating point number,
# then the continued fraction algorithm can find the best match for us.
#
# When using the quantum version, we have the flexibility to set key word arguments `nshot`,
# `nbit` (size of input data register) and `ncbit` (size of control register, or output register).
# `nbit` can be simply chosen as the minimum register size to store input,
# while `ncbit` can be estimated with the following function
"""estimate the required size of the output register."""
estimate_ncbit(nbit::Int, ϵ::Real) = 2*nbit + 1 + ceil(Int,log2(2+1/2ϵ))

get_order(::Val{:classical}, x::Int, L::Int; kwargs...) = NumberTheory.find_order(x, L)
function get_order(::Val{:quantum}, x::Int, L::Int; nshots::Int=10,
            nbit::Int=bit_length(L-1), ncbit::Int=estimate_ncbit(nbit, 0.25))
    c = order_finding_circuit(x, L; nbit=nbit, ncbit=ncbit)
    reg = join(product_state(nbit, 1), zero_state(ncbit))

    res = measure(copy(reg) |> c; nshots=nshots)
    for r in res
        ## split bit string b into lower bits `k` and higher bits `r`.
        mask = bmask(1:ncbit)
        k,i = r&mask, r>>ncbit
        ## get s/r
        ϕ = bfloat(k)  #
        ϕ == 0 && continue

        ## order_from_float: given a floating point number,
        ## return the closest rational number with bounded number of continued fraction steps.
        order = NumberTheory.order_from_float(ϕ, x, L)
        if order === nothing
            continue
        else
            return order
        end
    end
    return nothing
end

# #### The circuit used for finding order
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

# The circuit for order finding is consisted of three parts
# 1. Hadamard gates,
# 2. `KMod` that computes a classical function `mod(a^k*x, L)`.
# `k` is the integer stored in first `K` (or `ncbit`) qubits and the rest `N-K` qubits stores `a`.
# Notice it is not a basic gate, it should have been compiled to multiple gates, which is not implemented in `Yao` for the moment.
# To learn more about implementing arithmatics on a quantum circuit, please read [this paper](https://arxiv.org/abs/1805.12445).
# 3. Inverse quantum fourier transformation.

# ## Run
# Factorizing `15`, you should see `3` or `5`, please report a bug if it is not...
using Random; Random.seed!(109) #src
shor(15, Val(:quantum))
