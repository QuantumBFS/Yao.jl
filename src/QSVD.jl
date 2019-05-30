# Quantum SVD
# Reference: https://arxiv.org/abs/1905.01353
export QuantumSVD, circuit_qsvd, train_qsvd!, readout_qsvd

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
    c = circuit_qsvd(circuit_a, circuit_b, Nc) |> autodiff(:QC)   # construct a differentiable circuit for training

    obs = -mapreduce(i->put(nbit, i=>Z), +, (1:Na..., Na+Nc+1:Na+Nb...))
    params = parameters(c)
    for i = 1:maxiter
        grad = opdiff.(() -> copy(reg) |> c, collect_blocks(AbstractDiff, c), Ref(obs))
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
        circuit_a=random_diff_circuit(log2i(size(M, 1)), 5, pair_ring(log2i(size(M, 1)))),
        circuit_b=random_diff_circuit(log2i(size(M, 2)), 5, pair_ring(log2i(size(M, 2)))),
        maxiter=200, optimizer=Adam(lr=0.1))

    dispatch!(circuit_a, :random)
    dispatch!(circuit_b, :random)
    reg = ArrayReg(vec(M))
    train_qsvd!(reg, circuit_a, circuit_b, optimizer, Nc=Nc, maxiter=maxiter)
    readout_qsvd(reg, circuit_a, circuit_b, Nc)
end
