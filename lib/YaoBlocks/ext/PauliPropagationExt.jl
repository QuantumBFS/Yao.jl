module PauliPropagationExt
using YaoBlocks
using PauliPropagation
using YaoBlocks.ConstGate
using MLStyle

function pauli_to_yao_gate!(c::ChainBlock, g::Gate, parameter)
    @match g begin
        ::PauliRotation => push!(c, put(c.n, (g.qinds...,) => rot(kron(symbol_to_yao.(g.symbols)...), parameter)))
        ::DepolarizingNoise =>
            begin
                @assert length(g.qind) == 1 "Depolarizing noise should be applied to a single qubit"
                push!(c, put(c.n, (g.qind...,) => single_qubit_depolarizing_channel(parameter)))
            end
        ::PauliXNoise => push!(c, put(c.n, (g.qind...,) => MixedUnitaryChannel(PauliError( parameter / 2, 0.0, 0.0))))
        ::PauliYNoise => push!(c, put(c.n, (g.qind...,) => MixedUnitaryChannel(PauliError( 0.0, parameter / 2, 0.0))))
        ::PauliZNoise => push!(c, put(c.n, (g.qind...,) => MixedUnitaryChannel(PauliError( 0.0, 0.0, parameter / 2))))
        ::AmplitudeDampingNoise => quantum_channel(AmplitudeDampingError(parameter))
        _ => error("Unsupported gate type: $(typeof(g))")
    end
end

function YaoBlocks.pauli_to_yao_circuit(n::Int, circ::AbstractVector{<:Gate}, thetas::AbstractVector)
    @assert length(thetas) == countparameters(circ)
    thetas = copy(thetas)
    c = chain(n)
    for g in circ
        if g isa FrozenGate
            pauli_to_yao_gate!(c, g.gate, g.parameter)
        else
            pauli_to_yao_gate!(c, g, popfirst!(thetas))
        end
    end
    return c
end

function YaoBlocks.yao_to_pauli_circuit(circ::ChainBlock; frozen_rots::Bool=false)
    circ = YaoBlocks.Optimise.to_basictypes(circ)
    n = nqubits(circ)
    gates = Gate[]
    thetas = Float64[]
    for g in circ
        @match g begin
            ::PutBlock => yao_to_pauli_gates!(gates, thetas, g; frozen_rots=frozen_rots)
            _ => error("Unsupported gate type: $(typeof(g))")
        end
    end
    return n, gates, thetas
end

function yao_to_pauli_gates!(gates::Vector{Gate}, thetas, g; frozen_rots::Bool=false)
    @match g.content begin
        ::ConstantGate => push!(gates, CliffordGate(yao_to_symbols(g.content)[], collect(g.locs)))
        ::RotationGate =>
            if frozen_rots
                push!(gates, PauliRotation(yao_to_symbols(g.content.block), collect(g.locs), g.content.theta))
            else
                push!(gates, PauliRotation(yao_to_symbols(g.content.block), collect(g.locs)))
                push!(thetas, g.content.theta)
            end
        ::DepolarizingChannel =>
            begin
                push!(gates, DepolarizingNoise(g.locs[1]))
                push!(thetas, g.content.p)
            end
        ::AmplitudeDampingError =>
            begin
                push!(gates, AmplitudeDampingNoise(g.locs))
                push!(thetas, g.content.p)
            end
        ::MixedUnitaryChannel =>
            begin
                for (prob, operator) in zip(g.content.probs, g.content.operators)
                    if prob > 0
                        if operator isa YaoBlocks.XGate
                            push!(gates, PauliXNoise(g.locs[1]))
                            push!(thetas, 2 * prob)
                        elseif operator isa YaoBlocks.YGate
                            push!(gates, PauliYNoise(g.locs[1]))
                            push!(thetas, 2 * prob)
                        elseif operator isa YaoBlocks.ZGate
                            push!(gates, PauliZNoise(g.locs[1]))
                            push!(thetas, 2 * prob)
                        elseif !(operator isa YaoBlocks.I2Gate)
                            error("Unsupported error type: $(typeof(operator))")
                        end
                    else
                        continue
                    end
                end
            end

        _ => error("Unsupported gate type: $(typeof(g.content))")
    end
end

function yao_to_pauli_string(n, observable::Scale)
    coeff = observable.alpha
    return yao_to_pauli_string(n, observable.content; coeff=coeff)
end

function yao_to_pauli_string(n, observable::ChainBlock; coeff=1.0)
    @assert n == nqubits(observable)
    paulis = Symbol[]
    qinds = Int[]
    for s in observable
        push!(paulis, yao_to_symbol(s.content))
        push!(qinds, s.locs[1])
    end
    return PauliString(n, paulis, qinds, coeff)
end

function yao_to_pauli_string(n, observable::PutBlock; coeff=1.0)
    pauli = yao_to_symbol(observable.content)
    locs = observable.locs[1]
    return PauliString(n, pauli, locs, coeff)
end

const symbol_yao_map = Dict(
    :I => I2,
    :X => X,
    :Y => Y,
    :Z => Z,
    :H => H,
    :S => S,
    :T => T,
    :CNOT => CNOT,
)
const yao_symbol_map = Dict(values(symbol_yao_map) .=> keys(symbol_yao_map))

function symbol_to_yao(sym::Symbol)
    return symbol_yao_map[sym]
end

function yao_to_symbols(yaoblock::KronBlock)
    return [yao_to_symbol(b) for b in yaoblock.blocks]
end
yao_to_symbols(yaoblock) = [yao_to_symbol(yaoblock)]

function yao_to_symbol(yaoblock)
    return yao_symbol_map[yaoblock]
end

function YaoBlocks.expect(circ::ChainBlock, observable_or_state; backend=YaoBackend(), kwargs...)
    if backend == YaoBackend()
        return YaoBlocks.expect(circ, observable_or_state; kwargs...)
    elseif backend == PauliPropagationBackend()
        n, gates, thetas = YaoBlocks.yao_to_pauli_circuit(circ)
        pstr = yao_to_pauli_string(n, observable_or_state)
        psum = propagate(gates, pstr, thetas)
        return overlapwithzero(psum)
    else
        error("Unsupported backend type: $(typeof(backend))")
    end
end

function YaoBlocks.expect(circ::ChainBlock; backend=YaoBackend(), kwargs...)
    if backend == YaoBackend()
        return YaoBlocks.expect(circ, observable_or_state; kwargs...)
    elseif backend == PauliPropagationBackend()
        n, gates, thetas = YaoBlocks.yao_to_pauli_circuit(circ)
        pstr = yao_to_pauli_string(n, observable_or_state)
        psum = propagate(gates, pstr, thetas)
        return overlapwithzero(psum)
    else
        error("Unsupported backend type: $(typeof(backend))")
    end
end

end
