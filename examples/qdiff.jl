using Yao
using Yao.Blocks

layer(x::Symbol) = layer(Val(x))
layer(::Val{:first}) = rollrepeat(chain(Rx(0.0), Rz(0.0)))
layer(::Val{:last}) = rollrepeat(chain(Rz(0.0), Rx(0.0)))
layer(::Val{:mid}) = rollrepeat(chain(Rz(0.0), Rx(0.0), Rz(0.0)))
entangler(pairs) = chain(control([ctrl, ], target=>X) for (ctrl, target) in pairs)

function diff_circuit(n, nlayer, pairs)
    circuit = chain(n)
    push!(circuit, layer(:first))

    for i = 1:(nlayer - 1)
        push!(circuit, entangler(pairs) |> cache)
        push!(circuit, layer(:mid))
    end

    push!(circuit, entangler(pairs) |> cache)
    push!(circuit, layer(:last))

    dispatch!(circuit, rand(nparameters(circuit))*2π)
end

collect_blocks(func, blk::AbstractBlock) = collect_blocks!(func, Vector{AbstractBlock}([]), blk)

function collect_blocks!(func, rgs::Vector, blk::CompositeBlock)
    if func(blk) push!(rgs, blk) end
    for block in blocks(blk)
        collect_blocks(func, rgs, blk)
    end
    rgs
end

collect_blocks!(func, rgs::Vector, blk::PrimitiveBlock) = func(blk) ? push!(rgs, blk) : rgs
collect_blocks!(func, rgs::Vector, blk::TagBlock) = func(parent(blk)) ? push!(rgs, parent(blk)) : rgs

collect_rotblocks(blk::AbstractBlock) = collect_blocks!(x->x isa RotationGate, Vector{RotationGate}([]), blk)

# expectation value of operator
expect(op::AbstractBlock, reg::AbstractRegister) = (reg |> statevec)'*(reg |> op |> statevec)

import Base: gradient
function gradient(gradfunc, reg::AbstractRegister, circuit::AbstractBlock, gate::RotationGate)
    dispatch!(+, gate, pi / 2)
    prob_pos = copy(reg) |> circuit |> probs

    dispatch!(-, gate, pi)
    prob_neg = get_prob(qcbm)

    dispatch!(+, gate, pi / 2) # set back

    grad_func(prob_pos, prob_neg)
end

function gradient(gradfunc, reg::AbstractRegister, circuit::AbstractBlock; gates::Vector{RotationGate}=collect_rotblocks(circuit))
    map(gate->gradient(gradfunc, reg, circuit, gate), gates)
end

c = diff_circuit(4, 3, [1=>3, 2=>4, 2=>3, 4=>1])
println(c)
rots = collect_rotblocks(c)
nparameters(c)==length(rots) || throw(Exception("some parameters in this circuit are not differentiable!"))
grad = gradient((a,b) -> (a-b)/2, )
println()
