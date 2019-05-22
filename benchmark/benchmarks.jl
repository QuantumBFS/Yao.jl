# Benchmark Test for YaoArrayRegister
# NOTE: we only test the standard interface here:
# 1. locations are all tuples
#
# forwarded bindings should be tested in YaoBlocks via blocks.

using PkgBenchmark, BenchmarkTools
using YaoArrayRegister, BitBasis, Random, YaoBase, StaticArrays, LuxurySparse
using LinearAlgebra, SparseArrays

bench(n, U, loc::Tuple) = @benchmarkable instruct!(st, $U, $loc) setup=(st=statevec(rand_state($n)))
bench(n, U, loc::Tuple, control_locs::Tuple, control_bits::Tuple) = @benchmarkable instruct!(st, $U, $loc, $control_locs, $control_bits) setup=(st=statevec(rand_state($n)))

const SUITE = BenchmarkGroup()
SUITE["specialized"] = BenchmarkGroup()

@info "generating benchmark for specialized operators for single qubits"
# Specialized Gate Instruction
SUITE["specialized"]["single qubit"] = BenchmarkGroup()
## single qubit benchmark
for U in YaoArrayRegister.SPECIALIZATION_LIST, n in 1:4:25
    SUITE["specialized"]["single qubit"][string(U), n] = bench(n, Val(U), (1, ))
end

SUITE["specialized"]["single control"] = BenchmarkGroup()
for U in YaoArrayRegister.SPECIALIZATION_LIST, n in 4:4:25
    SUITE["specialized"]["single control"][string(U), n, (2, ), (1, )] = bench(n, Val(U), (1, ), (2, ), (1, ))
end

SUITE["specialized"]["multi control"] = BenchmarkGroup()

for U in YaoArrayRegister.SPECIALIZATION_LIST, n in 4:4:25
    control_locs = Tuple(2:n); control_bits = ntuple(x->1, n-1)
    SUITE["specialized"]["multi control"][string(U), n, 2:n, control_locs] = bench(n, Val(U), (1, ), control_locs, control_bits)
end

SUITE["specialized"]["multi qubit"] = BenchmarkGroup()
const location_sparsity = 0.4
@info "generating benchmark for specialized operators for multi qubits"
## multi qubit benchmark
for U in YaoArrayRegister.SPECIALIZATION_LIST, n in 4:4:25
    perms = randperm(n)[1:ceil(Int, location_sparsity * n)]
    SUITE["specialized"]["multi qubit"][string(U), n] = bench(n, Val(U), Tuple(perms))
end

SUITE["specialized"]["multi qubit multi control"] = BenchmarkGroup()
SUITE["specialized"]["single qubit multi control"] = BenchmarkGroup()

const control_rate = 0.3
for U in YaoArrayRegister.SPECIALIZATION_LIST, n in 4:4:25
    num_controls = ceil(Int, n * control_rate)
    perms = randperm(n)
    control_locs = Tuple(perms[1:num_controls]); control_bits = ntuple(x->rand(0:1), num_controls)
    perms = perms[num_controls+1:num_controls+round(Int, location_sparsity * n)]

    SUITE["specialized"]["multi qubit multi control"][string(U), n, num_controls] = bench(n, Val(U), Tuple(perms), control_locs, control_bits)
    SUITE["specialized"]["single qubit multi control"][string(U), n, num_controls] = bench(n, Val(U), (perms[1], ), control_locs, control_bits)
end

for n in 4:4:25
    SUITE["specialized"]["multi qubit"]["SWAP", n] = bench(n, Val(:SWAP), (1, 2))
    SUITE["specialized"]["multi qubit"]["SWAP", "random", n] = bench(n, Val(:SWAP), Tuple(randperm(n)[1:2]))
end

# General Instructions (matrices based)
SUITE["matrices"] = BenchmarkGroup()
SUITE["matrices"]["contiguous"] = BenchmarkGroup()
SUITE["matrices"]["contiguous"]["ordered"] = BenchmarkGroup()
SUITE["matrices"]["contiguous"]["random"] = BenchmarkGroup()

SUITE["matrices"]["in-contiguous"] = BenchmarkGroup()
SUITE["matrices"]["in-contiguous"]["ordered"] = BenchmarkGroup()
SUITE["matrices"]["in-contiguous"]["random"] = BenchmarkGroup()

SUITE["matrices"]["single qubit"] = BenchmarkGroup()
SUITE["matrices"]["single qubit"]["ordered"] = BenchmarkGroup()
SUITE["matrices"]["single qubit"]["random"] = BenchmarkGroup()


## General Matrix Instruction
function matrices(::Type{T}, N) where T
    list = Any[
        rand_unitary(T, N), # dense matrices
        # SparseMatrixCSC
        sprand_hermitian(T, N, 0.1),
        # PermMatrix
        pmrand(T, N),
        Diagonal(rand(T, N))
    ]
    if N < 100
        # StaticArrays
        push!(list, @SArray(rand(T, N, N)))
        push!(list, @MArray(rand(T, N, N)))
    end
    return list
end

# default test type is ComplexF64
matrices(N) = matrices(ComplexF64, N)

@info "generating benchmark for contiguous matrices locs"
### contiguous
for n in 1:2:10, T in [ComplexF64], U in matrices(T, 1<<n)
    # contiguous ordered address
    SUITE["matrices"]["contiguous"]["ordered"][n, string(T), string(typeof(U))] = bench(n, U, Tuple(1:n))
    # contiguous random address
    SUITE["matrices"]["contiguous"]["random"][n, string(T), string(typeof(U))] = bench(n, U, Tuple(randperm(n)))
end

@info "generating benchmark for in-contiguous matrices locs"
### in-contiguous
for m in 1:3, T in [ComplexF64], U in matrices(T, 1 << m)
    n = 10; N = 1 << n
    # in-contiguous ordered address
    SUITE["matrices"]["in-contiguous"]["ordered"][m, string(T), string(typeof(U))] = bench(n, U, Tuple(sort(randperm(n)[1:m])))
    # in-contiguous random address
    SUITE["matrices"]["in-contiguous"]["random"][m, string(T), string(typeof(U))] = bench(n, U, Tuple(randperm(n)[1:m]))
end

@info "generating benchmark for single qubit matrices"
### single qubit
for T in [ComplexF64], U in matrices(T, 2), n in 1:4:25
    SUITE["matrices"]["single qubit"]["ordered"][string(T), string(typeof(U)), n] = bench(n, U, (rand(1:n), ))
    SUITE["matrices"]["single qubit"]["random"][string(T), string(typeof(U)), n] = bench(n, U, (rand(1:n), ))
end

SUITE["matrices"]["controlled"] = BenchmarkGroup()
SUITE["matrices"]["controlled"]["ordered"] = BenchmarkGroup()
SUITE["matrices"]["controlled"]["random"] = BenchmarkGroup()

test_bench(n, U, loc, control_locs, control_bits) = instruct!(statevec(rand_state(n)), U, loc, control_locs, control_bits)
for T in [ComplexF64], n in 1:2:10, m in 3:2:6, U in matrices(T, 1<<n)
    SUITE["matrices"]["controlled"]["ordered"][n, m, string(T), string(typeof(U))] = bench(n+m, U, Tuple(1:n), Tuple(n+1:n+m), ntuple(x->1, m))

    perms = randperm(n+m)
    SUITE["matrices"]["controlled"]["random"][n, m, string(T), string(typeof(U))] = bench(n+m, U, Tuple(perms[1:n]), Tuple(perms[n+1:n+m]), ntuple(x->1, m))
end
