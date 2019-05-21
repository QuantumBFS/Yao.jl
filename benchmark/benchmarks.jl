using YaoArrayRegister, YaoBlocks, YaoBlocks.ConstGate, Random
using BenchmarkTools, PkgBenchmark

function bench(block)
    N = nqubits(block)
    r = rand_state(N)
    return @benchmarkable apply!($r, $block)
end

const SUITE = BenchmarkGroup()

SUITE["primitive"] = BenchmarkGroup()
SUITE["composite"] = BenchmarkGroup()

for G in [:X, :Y, :Z, :S, :T, :Sdag, :Tdag]
    GT = Expr(:(.), :ConstGate, QuoteNode(Symbol(G, :Gate)))
    GN = Expr(:(.), :ConstGate, QuoteNode(G))

    SUITE["primitive"][string(G)] = BenchmarkGroup()
    for n in 1:4:25
        SUITE["primitive"][string(G)][n] = @eval bench(repeat($n, $GN))
    end
end

for n in 5:5:25
    SUITE["composite"]["kron(rand_const)"] = bench(kron(rand([X, Y, Z, H]) for _ in 1:n))
    SUITE["composite"]["kron(sparse_const)"] = bench(kron(n, k=>rand([X, Y, Z, H]) for k in randperm(n)[1:n÷5]))
end

function heisenberg(n::Int; periodic::Bool=true)
    Sx(i) = put(n, i=>X)
    Sy(i) = put(n, i=>Y)
    Sz(i) = put(n, i=>Z)

    return sum(1:(periodic ? n : n-1)) do i
        j = mod1(i, n)
        Sx(i) * Sx(j) + Sy(i) * Sy(j) + Sz(i) * Sz(j)
    end
end

for n in 5:5:25
    SUITE["primitive"]["TimeEvolution(heisenberg(n), 0.2)"] = bench(TimeEvolution(heisenberg(n), 0.2))
end
