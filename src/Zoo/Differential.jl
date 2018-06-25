export diff_circuit, num_gradient, rotter, cnot_entangler, opgrad, collect_rotblocks

"""
    rotter(noleading::Bool=false, notrailing::Bool=false) -> ChainBlock{1, ComplexF64}

Arbitrary rotation unit, set parameters notrailing, noleading true to remove trailing and leading Z gates.
"""
rotter(noleading::Bool=false, notrailing::Bool=false) = noleading ? (notrailing ? Rx(0) : chain(Rx(0), Rz(0))) : (notrailing ? chain(Rz(0), Rx(0)) : chain(Rz(0), Rz(0), Rz(0)))

"""
    cnot_entangler([n::Int, ] pairs::Vector{Pair}) = ChainBlock

Arbitrary rotation unit, support lazy construction.
"""
#cnot_entangler(n::Int, pairs) = chain(n, control(n, [ctrl], target=>X) for (ctrl, target) in pairs)
#cnot_entangler(pairs) = n->cnot_entangler(n, pairs)
cnot_entangler(pairs) = chain(control([ctrl], target=>X) for (ctrl, target) in pairs)

"""
    diff_circuit(n, nlayer, pairs) -> ChainBlock

A kind of widely used differentiable quantum circuit, angles in the circuit is randomely initialized.

ref:
    1. Kandala, A., Mezzacapo, A., Temme, K., Takita, M., Chow, J. M., & Gambetta, J. M. (2017).
       Hardware-efficient Quantum Optimizer for Small Molecules and Quantum Magnets. Nature Publishing Group, 549(7671), 242–246.
       https://doi.org/10.1038/nature23879.
"""
function diff_circuit(n, nlayer, pairs)
    circuit = chain(n)

    for i = 1:(nlayer + 1)
        if i!=1  push!(circuit, cnot_entangler(pairs) |> cache) end
        push!(circuit, rollrepeat(n, rotter(i==1, i==nlayer+1)))
    end
    dispatch!(circuit, rand(nparameters(circuit))*2π)
end

"""
    collect_rotblocks(blk::AbstractBlock) -> Vector{RotationGate}

filter out all rotation gates, which is differentiable.
"""
function collect_rotblocks(blk::AbstractBlock)
    rots = blockfilter!(x->x isa RotationGate, Vector{RotationGate}([]), blk)
    nparameters(blk)==length(rots) || warn("some parameters in this circuit are not differentiable!")
    rots
end

import Base: gradient
function _wave_perturbation(circuit::AbstractBlock, reg0::AbstractRegister, gate::RotationGate, diff::Real)
    dispatch!(+, gate, diff)
    psi_pos = copy(reg0) |> circuit

    dispatch!(+, gate, -2*diff)
    psi_neg = copy(reg0) |> circuit

    dispatch!(+, gate, diff) # set back
    psi_pos, psi_neg
end

"""
    gradient(gradfunc, circuit::AbstractBlock[, reg0::AbstractRegister=zero_state(nqubits(circuit)),
                gates::Vector{RotationGate}=collect_rotblocks(circuit)]) -> Vector

"""
function gradient(gradfunc, circuit::AbstractBlock, reg0::AbstractRegister, gates::Vector{RotationGate}=collect_rotblocks(circuit))
    map(gate->gradfunc(_wave_perturbation(circuit, reg0, gate, π/2)...), gates)
end

gradient(gradfunc, circuit, gates::Vector{RotationGate}=collect_rotblocks(circuit)) = gradient(gradfunc, circuit, zero_state(nqubits(circuit)), gates)

"""
    num_gradient(lossfunc, circuit::AbstractBlock [, δ::Float64=1e-2,
                        reg0::AbstractRegister=zero_state(nqubits(circuit)),
                        gates::Vector{RotationGate}=collect_rotblocks(circuit)
                        ]) -> Vector
Compute gradient numerically.
"""
function num_gradient(lossfunc, circuit::AbstractBlock, δ::Float64, reg0::AbstractRegister, gates::Vector{RotationGate}=collect_rotblocks(circuit))
    map(gates) do gate
        rp, rn = _wave_perturbation(circuit, reg0, gate, δ)
        (lossfunc(rp) - lossfunc(rn))/2/δ
    end
end
num_gradient(lossfunc, circuit) = num_gradient(lossfunc, circuit, 1e-2, zero_state(nqubits(circuit)))

opgradfunc(op) = (reg_pos, reg_neg) -> (expect(op, reg_pos)-expect(op, reg_neg))/2

"""
    opgrad(op::AbstractBlock, circuit::AbstractBlock) -> Vector

get the gradient of an operator, which should be an observable.
"""
opgrad(op::AbstractBlock, circuit::AbstractBlock) = gradient(opgradfunc(op), circuit)
