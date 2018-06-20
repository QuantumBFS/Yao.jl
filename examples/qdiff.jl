using Yao
using Yao.Blocks

rotter(x::Symbol) = rotter(Val(x))
rotter(::Val{:first}) = rollrepeat(chain(Rx(0.0), Rz(0.0)))
rotter(::Val{:last}) = rollrepeat(chain(Rz(0.0), Rx(0.0)))
rotter(::Val{:mid}) = rollrepeat(chain(Rz(0.0), Rx(0.0), Rz(0.0)))
entangler(pairs) = chain(control([ctrl], target=>X) for (ctrl, target) in pairs)

function diff_circuit(n, nlayer, pairs)
    circuit = chain(n)
    push!(circuit, rotter(:first))

    for i = 1:(nlayer - 1)
        push!(circuit, entangler(pairs) |> cache)
        push!(circuit, rotter(:mid))
    end

    push!(circuit, entangler(pairs) |> cache)
    push!(circuit, rotter(:last))

    dispatch!(circuit, rand(nparameters(circuit))*2π)
end

function collect_rotblocks(blk::AbstractBlock)
    rots = collect_blocks!(x->x isa RotationGate, Vector{RotationGate}([]), blk)
    nparameters(c)==length(rots) || warn("some parameters in this circuit are not differentiable!")
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

function gradient(gradfunc, circuit::AbstractBlock, reg0::AbstractRegister, gates::Vector{RotationGate}=collect_rotblocks(circuit))
    map(gate->gradfunc(_wave_perturbation(circuit, reg0, gate, π/2)...), gates)
end

gradient(gradfunc, circuit, gates::Vector{RotationGate}=collect_rotblocks(circuit)) = gradient(gradfunc, circuit, zero_state(nqubits(circuit)), gates)

function num_gradient(lossfunc, circuit::AbstractBlock, δ::Float64, reg0::AbstractRegister, gates::Vector{RotationGate}=collect_rotblocks(circuit))
    map(gates) do gate
        rp, rn = _wave_perturbation(circuit, reg0, gate, δ)
        (lossfunc(rp) - lossfunc(rn))/2/δ
    end
end
num_gradient(lossfunc, circuit) = num_gradient(lossfunc, circuit, 1e-2, zero_state(nqubits(circuit)))

c = diff_circuit(4, 3, [1=>3, 2=>4, 2=>3, 4=>1])
println(c)
rots = collect_rotblocks(c)

obs = kron(nqubits(c), 2=>X)
opgradfunc(op) = (reg_pos, reg_neg) -> (expect(op, reg_pos)-expect(op, reg_neg))/2
obsgrad(op::AbstractBlock, circuit::AbstractBlock) = gradient(opgradfunc(op), c)
isapprox(obsgrad(obs, c),  num_gradient(r->expect(obs, r), c), atol=1e-3)
