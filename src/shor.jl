include("number_theory.jl")
include("Mod.jl")

export shor, order_finding_circuit, get_order

"""
    shor(L::Int, ver=Val(:quantum); maxtry=100)

factorize an integer `L`, `ver` can be either `Val(:quantum)` or `Val(:classical)`.
"""
function shor(L::Int, ver=Val(:quantum); maxtry=100)
    L%2 == 0 && return 2

    # find solutions like `a^b`
    res = NumberTheory.factor_a_power_b(L)
    res !== nothing && return res[1]

    for i in 1:maxtry
        x = NumberTheory.rand_primeto(L)
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

"""estimate the required size of the output register."""
estimate_ncbit(nbit::Int, ϵ::Real) = 2*nbit + 1 + ceil(Int,log2(2+1/2ϵ))

"""
    order_finding_circuit(x::Int, L::Int; nbit::Int=bit_length(L-1), ncbit::Int=estimate_ncbit(nbit, 0.25)) -> AbstractBlock

Returns the circuit for finding the order of `x` to `L`,
feeding input `|1>⊗|0>` will get the resulting quantum register with the desired "phase" information.
"""
function order_finding_circuit(x::Int, L::Int; nbit::Int=bit_length(L-1), ncbit::Int=estimate_ncbit(nbit, 0.25))
    N = nbit+ncbit
    chain(N, repeat(N, H, 1:ncbit),KMod{N, ncbit}(x, L), concentrate(N, QFTBlock{ncbit}()', 1:ncbit))
end

"""
    find_order([ver], x::Int, N::Int; nshots=10) -> Union{Int, Nothing}

Get the order of `x`, `ver` can be `Val(:classical)` (default) or `Val(:quantum)`,
when using the quantum approach, we can set key word arguments `nshot`,
`nbit` (size of input data register) and `ncbit` (size of control register, or output register).
"""
get_order(::Val{:classical}, x::Int, N::Int; kwargs...) = NumberTheory.find_order(x, N)
function get_order(::Val{:quantum}, x::Int, N::Int; nshots=10, kwargs...)
    c = order_finding_circuit(x, N; kwargs...)
    n = nqubits_data(c[2])
    ncbit = nqubits_control(c[2])
    reg = join(product_state(n, 1), zero_state(ncbit))

    res = measure(copy(reg) |> c; nshots=nshots)
    reader = bint2_reader(Int, ncbit)
    for r in res
        k, i = reader(r)
        # get s/r
        ϕ = bfloat(k)  #
        ϕ == 0 && continue

        order = NumberTheory.order_from_float(ϕ, x, N)
        if order === nothing
            continue
        else
            return order
        end
    end
    return nothing
end
