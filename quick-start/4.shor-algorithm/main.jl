# # [Shor's Algorithm](@id Shor)

# ## References
# * [Neilsen](https://aapt.scitation.org/doi/abs/10.1119/1.1463744?journalCode=ajp)
# * [An Insightful Blog](https://algassert.com/post/1718)

# ## Main Program
# The main program of a Shor's algorithm can be summrized in several lines of code.
# For the theory part, please refer the reference materials above.
# It factorize an integer `L`, and returns one of the factors.
# Here, the input `ver` can be either `Val(:quantum)` or `Val(:classical)`,
# where the classical version is for comparison.

using Yao, BitBasis
using YaoExtensions: KMod, QFTCircuit
using QuAlgorithmZoo: NumberTheory

function shor(L::Int, ver=Val(:quantum); maxtry=100)
    L%2 == 0 && return 2

    ## find short cut solutions like `a^b`
    res = NumberTheory.factor_a_power_b(L)
    res !== nothing && return res[1]

    for i in 1:maxtry
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
# The complexity of this algorithm is polynoial.
# 2. get the order `x`, i.e. finding a number `r` that satisfies `mod(x^r, L) = 1`.
# If `r` is even and `x^(r÷2)` is non-trivil, go on, otherwise start another try.
# Here, trivil means equal to `L-1 (mod L)`.
# 3. According to Theorem 5.2 in Neilsen book,
# one of `gcd(x^(r÷2)-1, L)` and `gcd(x^(r÷2)+1, L)` must be a non-trivil (`!=1`) factor of `L`.
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
    chain(N, repeat(N, H, 1:ncbit), KMod{N, ncbit}(x, L),
        concentrate(N, QFTCircuit(ncbit)', 1:ncbit))
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
using Random; Random.seed!(129) #src
shor(15, Val(:quantum))
