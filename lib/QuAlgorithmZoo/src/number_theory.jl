export NumberTheory

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
