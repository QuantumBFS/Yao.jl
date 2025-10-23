module PauliPropagationExt
using YaoBlocks
using PauliPropagation
using YaoBlocks.ConstGate
using MLStyle

export yao2paulipropagation, paulipropagation2yao, PauliPropagationCircuit
export yao2pauli  # Backward compatibility alias

"""
    PauliPropagationCircuit{IT<:Integer}

An intermediate representation of a quantum circuit in the Pauli propagation framework.

### Fields
- `n::Int`: Number of qubits
- `gates::Vector{Gate}`: Vector of PauliPropagation gates
- `thetas::Vector{Float64}`: Gate parameters
- `observable::PauliSum`: Observable to measure (sum of Pauli strings)

### Usage
```julia
pc = yao2paulipropagation(circuit; observable=obs)
result = propagate(pc)
```
"""
struct PauliPropagationCircuit{IT<:Integer}
    n::Int
    gates::Vector{StaticGate}
    thetas::Vector{Float64}
    observable::PauliSum{IT, Float64}
end

function Base.show(io::IO, pc::PauliPropagationCircuit)
    print(io, "PauliPropagationCircuit")
    print(io, "\n  Qubits: ", pc.n)
    print(io, "\n  Gates: ", length(pc.gates))
    print(io, "\n  Parameters: ", length(pc.thetas))
    print(io, "\n  Observable: ", pc.observable)
end

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

const AllowedObservableTypes = Union{
    KronBlock{<:Any, <:Any, <:NTuple{<:Any, ConstGate.PauliGate}},
    Scale{<:Any, <:Any, <:KronBlock{<:Any, <:Any, <:NTuple{<:Any, ConstGate.PauliGate}}},
    PutBlock{<:Any, <:Any, <:ConstGate.PauliGate}}
    Scale{<:Any, <:Any, <:PutBlock{<:Any, <:Any, <:ConstGate.PauliGate}},

"""
    yao2paulipropagation(circuit::ChainBlock; observable)

Convert a Yao quantum circuit to a PauliPropagationCircuit intermediate representation.

### Arguments
- `circuit::ChainBlock`: The quantum circuit to convert. Must contain only gates supported by PauliPropagation.

### Keyword Arguments
- `observable`: A Yao block specifying the observable to measure, which must be a sum of Pauli strings. e.g. `kron(5, 2=>X, 3=>X) + 2.0 * kron(5, 1=>Z)`

### Returns
- `PauliPropagationCircuit`: An intermediate representation containing the circuit and observable.

### Example
```julia
using Yao, YaoBlocks, PauliPropagation
circuit = chain(3, put(3, 1=>Rx(0.5)), put(3, 2=>X), control(3, 1, 2=>Y))
obs = put(3, 1=>Z)
pc = yao2paulipropagation(circuit; observable=obs)
psum = propagate(pc)  # Returns a PauliSum
result = overlapwithzero(psum)  # Get expectation value
```
"""
function YaoBlocks.yao2paulipropagation(circuit::ChainBlock; observable)
    circ = YaoBlocks.Optimise.to_basictypes(circuit)
    n = nqubits(circ)
    gates = StaticGate[]
    thetas = Float64[]
    
    # Convert circuit gates
    for g in circ
        @match g begin
            ::PutBlock => yao_to_pauli_gates!(gates, thetas, g)
            _ => error("Unsupported gate type: $(typeof(g))")
        end
    end
    
    # Convert observable
    obs = Optimise.eliminate_nested(observable)
    @assert obs isa AllowedObservableTypes || obs isa Add && all(b isa AllowedObservableTypes for b in subblocks(obs)) "Observable must be a sum of Pauli strings, e.g. kron(5, 2=>X, 3=>X) + 2.0 * kron(5, 1=>Z), got: $obs"
    return PauliPropagationCircuit(n, gates, thetas, PauliSum(cast_observable(observable)))
end

"""
    propagate(pc::PauliPropagationCircuit; kwargs...)

Propagate a Pauli observable through the circuit using Pauli propagation.

### Arguments
- `pc::PauliPropagationCircuit`: The circuit containing gates, parameters, and the observable to propagate.
- `kwargs...`: Additional keyword arguments passed to the underlying `propagate` function (e.g., `max_weight`, `min_abs_coeff`).

### Returns
- A `PauliSum` representing the propagated observable. Use `overlapwithzero(psum)` to get the expectation value.

### Example
```julia
pc = yao2paulipropagation(circuit; observable=obs)
psum = propagate(pc)  # Returns a PauliSum
result = overlapwithzero(psum)  # Get expectation value
```
"""
function PauliPropagation.propagate(pc::PauliPropagationCircuit; kwargs...)
    return propagate(pc.gates, pc.observable, pc.thetas; kwargs...)
end

"""
    paulipropagation2yao(n::Int, circ::AbstractVector{<:Gate}, thetas::AbstractVector)
    paulipropagation2yao(pc::PauliPropagationCircuit)

Convert a PauliPropagation circuit back to a Yao circuit.

### Arguments
- `n::Int`: Number of qubits
- `circ::AbstractVector{<:Gate}`: Vector of PauliPropagation gates
- `thetas::AbstractVector`: Gate parameters

Or:
- `pc::PauliPropagationCircuit`: A PauliPropagationCircuit intermediate representation

### Returns
- `ChainBlock`: A Yao quantum circuit
"""
function YaoBlocks.paulipropagation2yao(n::Int, circ::AbstractVector{<:Gate}, thetas::AbstractVector)
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

YaoBlocks.paulipropagation2yao(pc::PauliPropagationCircuit) = paulipropagation2yao(pc.n, pc.gates, pc.thetas)

function yao_to_pauli_gates!(gates::Vector{StaticGate}, thetas, g)
    @match g.content begin
        ::ConstantGate => push!(gates, CliffordGate(yao_to_symbols(g.content)[], collect(g.locs)))
        ::RotationGate => push!(gates, PauliRotation(yao_to_symbols(g.content.block), collect(g.locs), g.content.theta))
        ::DepolarizingChannel =>
            begin
                push!(gates, FrozenGate(DepolarizingNoise(g.locs[1]), g.content.p))
            end
        ::AmplitudeDampingError =>
            begin
                push!(gates, FrozenGate(AmplitudeDampingNoise(g.locs), g.content.p))
            end
        ::MixedUnitaryChannel =>
            begin
                for (prob, operator) in zip(g.content.probs, g.content.operators)
                    if prob > 0
                        if operator isa YaoBlocks.XGate
                            push!(gates, FrozenGate(PauliXNoise(g.locs[1]), 2 * prob))
                        elseif operator isa YaoBlocks.YGate
                            push!(gates, FrozenGate(PauliYNoise(g.locs[1]), 2 * prob))
                        elseif operator isa YaoBlocks.ZGate
                            push!(gates, FrozenGate(PauliZNoise(g.locs[1]), 2 * prob))
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

function cast_observable(observable::Add)
    return PauliSum([cast_observable(b) for b in subblocks(observable)])
end
function cast_observable(observable::Scale)
    return cast_observable(observable.content) * observable.alpha
end
function cast_observable(observable::KronBlock)
    n = nqubits(observable)
    return PauliString(n, [yao_to_symbol(block) for block in observable.blocks], [loc[1] for loc in observable.locs])
end
function cast_observable(observable::PutBlock)
    n = nqubits(observable)
    pauli = yao_to_symbol(observable.content)
    locs = observable.locs[1]
    return PauliString(n, pauli, locs)
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

end
