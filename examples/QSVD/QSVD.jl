using QuAlgorithmZoo, Yao,YaoExtensions
using BitBasis: log2i
using Test
using Random, LinearAlgebra

"""
Quantum singular value decomposition algorithm.

    * `reg`, input register (A, B) as the target matrix to decompose,
    * `circuit_a`, U matrix applied on register A,
    * `circuit_b`, V matrix applied on register B,
    * `optimizer`, the optimizer, normally we use `Adam(lr=0.1)`,
    * `Nc`, log2 number of singular values kept,
    * `maxiter`, the maximum number of iterations.
"""
function train_qsvd!(reg, circuit_a::AbstractBlock{Na}, circuit_b::AbstractBlock{Nb}, optimizer; Nc::Int=min(Na, Nb), maxiter::Int=100) where {Na, Nb}
    nbit = Na+Nb
    c = circuit_qsvd(circuit_a, circuit_b, Nc)

    obs = -mapreduce(i->put(nbit, i=>Z), +, (1:Na..., Na+Nc+1:Na+Nb...))
    params = parameters(c)
    for i = 1:maxiter
        grad = expect'(obs, reg => c).second
        QuAlgorithmZoo.update!(params, grad, optimizer)
        println("Iter $i, Loss = $(Na+expect(obs, copy(reg) |> c))")
        dispatch!(c, params)
    end
end

"""build the circuit for quantum SVD training."""
function circuit_qsvd(circuit_a::AbstractBlock{Na}, circuit_b::AbstractBlock{Nb}, Nc::Int) where {Na, Nb}
    nbit = Na+Nb
    cnots = chain(control(nbit, i+Na, i=>X) for i=1:Nc)
    c = chain(concentrate(nbit, circuit_a, 1:Na), concentrate(nbit, circuit_b, Na+1:nbit), cnots)
end

"""read QSVD results"""
function readout_qsvd(reg::AbstractRegister, circuit_a::AbstractBlock{Na}, circuit_b::AbstractBlock{Nb}, Nc::Int) where {Na, Nb}
    reg = copy(reg) |> concentrate(Na+Nb, circuit_a, 1:Na) |> concentrate(Na+Nb, circuit_b, Na+1:Na+Nb)
    _S = [select(reg, b|b<<Na).state[] for b in basis(Nc)]
    S = abs.(_S)
    order = sortperm(S, rev=true)
    S, _S = S[order], _S[order]
    mat(circuit_a)[order,:]'.*transpose(_S./S), S, transpose(mat(circuit_b)[order,:])
end

"""
    QuantumSVD(M; kwargs...)
Quantum SVD.
    * `M`, the matrix to decompose, size should be (2^Na × 2^Nb), the sum of squared spectrum must be 1.
kwargs includes
    * `Nc`, log2 number of singular values kept,
    * `circuit_a` and `circuit_b`, the circuit ansatz for `U` and `V` matrices,
    * `maxiter`, maximum number of iterations,
    * `optimizer`, default is `Adam(lr=0.1)`.
"""
function QuantumSVD(M::AbstractMatrix; Nc::Int=log2i(min(size(M)...)),
        circuit_a=variational_circuit(log2i(size(M, 1))),
        circuit_b=variational_circuit(log2i(size(M, 2))),
        maxiter=200, optimizer=Adam(lr=0.1))

    dispatch!(circuit_a, :random)
    dispatch!(circuit_b, :random)
    reg = ArrayReg(vec(M))
    train_qsvd!(reg, circuit_a, circuit_b, optimizer, Nc=Nc, maxiter=maxiter)
    readout_qsvd(reg, circuit_a, circuit_b, Nc)
end

@testset "QSVD" begin
    Random.seed!(2)
    # define a matrix of size (2^Na, 2^Nb)
    Na = 2
    Nb = 2

    # the exact result
    M = reshape(rand_state(Na+Nb).state, 1<<Na, 1<<Nb)
    U_exact, S_exact, V_exact = svd(M)

    U, S, V = QuantumSVD(M; maxiter=400)

    @test isapprox(U*Diagonal(S)*V', M, atol=1e-2)
    @test isapprox(abs.(S), S_exact, atol=1e-2)
    @test isapprox(U'*U_exact .|> abs2, I, atol=1e-2)
    @test isapprox(V'*V_exact .|> abs2, I, atol=1e-2)
end
