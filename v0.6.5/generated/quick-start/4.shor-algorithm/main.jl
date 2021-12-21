using Yao, BitBasis
using YaoExtensions: KMod, QFTCircuit
using QuAlgorithmZoo: NumberTheory

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
    chain(N, repeat(N, H, 1:ncbit), KMod{N, ncbit}(x, L),
        subroutine(N, QFTCircuit(ncbit)', 1:ncbit))
end

shor(15, Val(:quantum))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

