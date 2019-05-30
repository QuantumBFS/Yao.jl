using StatsBase: sample

export pair_ring, pair_square, cnot_entangler
export rotor, merged_rotor, rotorset
export random_diff_circuit
export rand_single_gate, rand_gate, rand_circuit

################## Entangler ###################
"""
    pair_ring(n::Int) -> Vector

Pair ring.
"""
pair_ring(n::Int) = [i=>mod(i, n)+1 for i=1:n]

"""
    pair_square(m::Int, n::Int) -> Vector

Pair square.
"""
function pair_square(m::Int, n::Int)
    nsite = m*n
    res = Vector{Pair{Int, Int}}(undef, 2*nsite)
    li = LinearIndices((m, n))
    k = 1
    for i = 1:2:m, j=1:n
        res[k] = li[i, j] => li[i%m+1, j]
        k+=1
    end
    for i = 2:2:m, j=1:n
        res[k] = li[i, j] => li[i%m+1, j]
        k+=1
    end
    for i = 1:m, j=1:2:n
        res[k] = li[i, j] => li[i, j%n+1]
        k+=1
    end
    for i = 1:m, j=2:2:n
        res[k] = li[i, j] => li[i, j%n+1]
        k+=1
    end
    res
end

"""
    cnot_entangler([n::Int, ] pairs::Vector{Pair}) = ChainBlock

Arbitrary rotation unit, support lazy construction.
"""
cnot_entangler(n::Int, pairs) = chain(n, control(n, [ctrl], target=>X) for (ctrl, target) in pairs)
cnot_entangler(pairs) = n->cnot_entangler(n, pairs)

###################### rotor and rotorset #####################
"""
    merged_rotor(noleading::Bool=false, notrailing::Bool=false) -> ChainBlock{1, ComplexF64}

Single qubit arbitrary rotation unit, set parameters notrailing, noleading true to remove trailing and leading Z gates.

!!! note

    Here, `merged` means `Rz(η)⋅Rx(θ)⋅Rz(ξ)` are multiplied first, this kind of operation if now allowed in differentiable
    circuit with back-propagation (`:BP`) mode (just because we are lazy to implement it!).
    But is a welcoming component in quantum differentiation.
"""
merged_rotor(noleading::Bool=false, notrailing::Bool=false) = noleading ? (notrailing ? Rx(0) : chain(Rx(0), Rz(0))) : (notrailing ? chain(Rz(0), Rx(0)) : chain(Rz(0), Rx(0), Rz(0)))

"""
    rotor(nbit::Int, ibit::Int, noleading::Bool=false, notrailing::Bool=false) -> ChainBlock{nbit, ComplexF64}

Arbitrary rotation unit (put in `nbit` space), set parameters notrailing, noleading true to remove trailing and leading Z gates.
"""
function rotor(nbit::Int, ibit::Int, noleading::Bool=false, notrailing::Bool=false)
    rt = chain(nbit, [put(nbit, ibit=>Rz(0.0)), put(nbit, ibit=>Rx(0.0)), put(nbit, ibit=>Rz(0.0))])
    noleading && popfirst!(rt)
    notrailing && pop!(rt)
    rt
end

rotorset(::Val{:Merged}, nbit::Int, noleading::Bool=false, notrailing::Bool=false) = chain(nbit, [put(nbit, j=>merged_rotor(noleading, notrailing)) for j=1:nbit])
rotorset(::Val{:Split}, nbit::Int, noleading::Bool=false, notrailing::Bool=false) = chain(nbit, [rotor(nbit, j, noleading, notrailing) for j=1:nbit])
rotorset(mode::Symbol, nbit::Int, noleading::Bool=false, notrailing::Bool=false) = rotorset(Val(mode), nbit, noleading, notrailing)

"""
    random_diff_circuit(nbit, nlayer, pairs; mode=:Split, do_cache=false)

A kind of widely used differentiable quantum circuit, angles in the circuit is randomely initialized.

ref:
    1. Kandala, A., Mezzacapo, A., Temme, K., Takita, M., Chow, J. M., & Gambetta, J. M. (2017).
       Hardware-efficient Quantum Optimizer for Small Molecules and Quantum Magnets. Nature Publishing Group, 549(7671), 242–246.
       https://doi.org/10.1038/nature23879.
"""
function random_diff_circuit(nbit, nlayer, pairs; mode=:Split, do_cache=false)
    circuit = chain(nbit)

    ent = cnot_entangler(pairs)
    if do_cache
        ent = ent |> cache
    end
    for i = 1:(nlayer + 1)
        i!=1 && push!(circuit, ent)
        push!(circuit, rotorset(mode, nbit, i==1, i==nlayer+1))
    end
    circuit
end

############### Completely random circuits (for testing and demo) ################
randlocs(nbit::Int, mbit::Int) = sample(1:nbit, mbit, replace=false)
const SINGLE_GATES = [X, Y, Z, H, Rx, Ry, Rz, shift, phase]

rand_single_gate(ngate::Int) = [rand_single_gates() for i=1:ngate]
function rand_single_gate()
    gate = rand(SINGLE_GATES)
    gate isa AbstractBlock ? gate : gate(rand()*2π)
end

"""
    rand_gate(nbit::Int, mbit::Int, [ngate::Int]) -> AbstractBlock

random nbit gate.
"""
rand_gate(nbit::Int, mbit::Int) = rand_gate(nbit, Val(mbit))
rand_gate(nbit::Int, mbit::Int, ngate::Int) = [rand_gate(nbit, mbit) for i=1:ngate]
rand_gate(nbit::Int, ::Val{1}) = put(nbit, rand(1:nbit)=>rand_single_gate())
function rand_gate(nbit::Int, ::Val{M}) where M
    locs = randlocs(nbit, M)
    control(nbit, locs[1:M-1], last(locs)=>rand_single_gate())
end

function rand_circuit(nbit::Int; p1 = (nbit==1 ? 1.0 : 0.66), ngate=5*nbit)
    c = chain(nbit)
    for i=1:ngate
        if rand() < p1
            push!(c, rand_gate(nbit, 1))
        else
            push!(c, rand_gate(nbit, 2))
        end
    end
    c
end
