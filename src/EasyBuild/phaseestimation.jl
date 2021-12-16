export phase_estimation_circuit, phase_estimation_analysis

"""
    phase_estimation_circuit(unitarygate::GeneralMatrixBlock, n_reg, n_b) -> ChainBlock

Phase estimation circuit. Input arguments are

* `unitarygate`: the input unitary matrix.
* `n_reg`: the number of bits to store phases,
* `n_b`: the number of bits to store vector.

References
----------------------
[Wiki](https://en.wikipedia.org/wiki/Quantum_phase_estimation_algorithm)
"""
function phase_estimation_circuit(unitarygate::GeneralMatrixBlock, n_reg::Int, n_b::Int)
    nbit = n_b + n_reg
    # Apply Hadamard Gate.
    hs = repeat(nbit, H, 1:n_reg)

    # Construct a control circuit.
    control_circuit = chain(nbit)
    for i = 1:n_reg
        push!(control_circuit, control(nbit, (i,), (n_reg+1:nbit...,)=>unitarygate))
        if i != n_reg
            unitarygate = matblock(mat(unitarygate) * mat(unitarygate))
        end
    end

    # Inverse QFT Block.
    iqft = subroutine(nbit, qft_circuit(n_reg)',[1:n_reg...,])
    chain(hs, control_circuit, iqft)
end

"""
    phase_estimation_analysis(eigenvectors::Matrix, reg::ArrayReg) -> Tuple

Analyse phase estimation result using state projection.
It returns a tuple of (most probable configuration, the overlap matrix, the relative probability for this configuration)
`eigenvectors` is the eigen vectors of the unitary gate matrix, while `reg` is the result of phase estimation.
"""
function phase_estimation_analysis(eigenvectors::AbstractMatrix, reg::ArrayReg)
    overlap = eigenvectors'*state(reg)
    amp_relative = Float64[]
    bs = Int[]

    for b in basis(overlap)
        mc = argmax(view(overlap, b+1, :) .|> abs)-1
        push!(amp_relative, abs2(overlap[b+1, mc+1])/sum(overlap[b+1, :] .|> abs2))
        push!(bs, mc)
    end
    bs, overlap, amp_relative
end