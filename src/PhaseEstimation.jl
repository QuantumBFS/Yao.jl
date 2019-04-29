export PEBlock, projection_analysis
"""
    PEBlock(UG, n_reg, n_b) -> ChainBlock

phase estimation circuit.

    * `UG`: the input unitary matrix.
    * `n_reg`: the number of bits to store phases,
    * `n_b`: the number of bits to store vector.
"""
function PEBlock(UG::GeneralMatrixBlock, n_reg::Int, n_b::Int)
    nbit = n_b + n_reg
    # Apply Hadamard Gate.
    hs = repeat(nbit, H, 1:n_reg)

    # Construct a control circuit.
    control_circuit = chain(nbit)
    for i = 1:n_reg
        push!(control_circuit, control(nbit, (i,), (n_reg+1:nbit...,)=>UG))
        if i != n_reg
            UG = matblock(mat(UG) * mat(UG))
        end
    end

    # Inverse QFT Block.
    iqft = concentrate(nbit, QFTBlock{n_reg}()',[1:n_reg...,])
    chain(hs, control_circuit, iqft)
end

"""
    projection_analysis(evec::Matrix, reg::ArrayReg) -> Tuple

Analyse using state projection.
It returns a tuple of (most probable configuration, the overlap matrix, the relative probability for this configuration)
"""
function projection_analysis(evec::Matrix, reg::ArrayReg)
    overlap = evec'*state(reg)
    amp_relative = Float64[]
    bs = Int[]

    for b in basis(overlap)
        mc = argmax(view(overlap, b+1, :) .|> abs)-1
        push!(amp_relative, abs2(overlap[b+1, mc+1])/sum(overlap[b+1, :] .|> abs2))
        push!(bs, mc)
    end
    bs, overlap, amp_relative
end
