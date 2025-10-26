module PauliPropagationExt
using YaoBlocks
using PauliPropagation
using YaoBlocks.ConstGate
using MLStyle
using LinearAlgebra: Diagonal

export yao2paulipropagation, paulipropagation2yao, PauliPropagationCircuit
export yao2pauli  # Backward compatibility alias

"""
    PauliPropagationCircuit{IT<:Integer}

An intermediate representation of a quantum circuit in the Pauli propagation framework.

### Fields
- `n::Int`: Number of qubits
- `gates::Vector{Gate}`: Vector of PauliPropagation gates
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
    observable::PauliSum{IT, Float64}
end

function Base.show(io::IO, pc::PauliPropagationCircuit)
    print(io, "PauliPropagationCircuit")
    print(io, "\n  Qubits: ", pc.n)
    print(io, "\n  Gates: ", length(pc.gates))
    print(io, "\n  Observable: ", pc.observable)
end

function pauli_to_yao_gate!(c::ChainBlock, g::Gate, parameter)
    @match g begin
        ::CliffordGate => begin
            # Check if it's a controlled gate
            if g.symbol ∈ [:CNOT, :CZ]
                @assert length(g.qinds) == 2 "Controlled gates should have exactly 2 qubits"
                ctrl_loc, target_loc = g.qinds
                if g.symbol == :CNOT
                    push!(c, control(c.n, ctrl_loc, target_loc=>X))
                elseif g.symbol == :CZ
                    push!(c, control(c.n, ctrl_loc, target_loc=>Z))
                end
            elseif g.symbol == :ZZpihalf
                # Special handling for ZZpihalf two-qubit gate
                @assert length(g.qinds) == 2 "ZZpihalf gate should have exactly 2 qubits"
                push!(c, put(c.n, (g.qinds...,) => rot(kron(Z,Z), π/2)))
            else
                # Single qubit Clifford gate
                push!(c, put(c.n, (g.qinds...,) => symbol_to_yao(g.symbol)))
            end
        end
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
    PutBlock{<:Any, <:Any, <:ConstGate.PauliGate},
    Scale{<:Any, <:Any, <:PutBlock{<:Any, <:Any, <:ConstGate.PauliGate}}}

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
    circ = YaoBlocks.Optimise.eliminate_nested(YaoBlocks.Optimise.to_basictypes(circuit))
    n = nqubits(circ)
    gates = StaticGate[]
    
    # Convert circuit gates
    for g in circ
        @match g begin
            ::PutBlock => yao_to_pauli_gates!(gates, g)
            ::ControlBlock => yao_to_pauli_control!(gates, g, n)
            _ => error("Unsupported gate type: $(typeof(g))")
        end
    end
    
    # Convert observable
    obs = YaoBlocks.Optimise.eliminate_nested(observable)
    @assert obs isa AllowedObservableTypes || obs isa Add && all(b isa AllowedObservableTypes for b in subblocks(obs)) "Observable must be a sum of Pauli strings, e.g. kron(5, 2=>X, 3=>X) + 2.0 * kron(5, 1=>Z), got: $obs"
    psum = cast_observable(observable)
    return PauliPropagationCircuit(n, gates, psum isa PauliSum ? psum : PauliSum([psum]))
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
    return propagate(pc.gates, pc.observable, Float64[]; kwargs...)
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
        elseif g isa CliffordGate
            pauli_to_yao_gate!(c, g, nothing)
        elseif g isa ParametrizedGate
            pauli_to_yao_gate!(c, g, popfirst!(thetas))
        else
            error("Unsupported gate type: $(typeof(g))")
        end
    end
    return c
end

YaoBlocks.paulipropagation2yao(pc::PauliPropagationCircuit) = paulipropagation2yao(pc.n, pc.gates, Float64[])

function yao_to_pauli_gates!(gates::Vector{StaticGate}, g)
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

function yao_to_pauli_control!(gates::Vector{StaticGate}, g::ControlBlock, n::Int)
    # Handle controlled gates
    # For now, support single-control single-target gates (CNOT, CZ, CY)
    @assert length(g.ctrl_locs) == 1 && length(g.locs) == 1 "Only single-control single-target gates are currently supported"
    @assert all(g.ctrl_config .== 1) "Only positive controls (ctrl_config=1) are supported"
    
    ctrl_loc = g.ctrl_locs[1]
    @match g.content begin
        ::XGate => push!(gates, CliffordGate(:CNOT, [ctrl_loc, g.locs[1]]))
        ::ZGate => push!(gates, CliffordGate(:CZ, [ctrl_loc, g.locs[1]]))
        _ => error("Unsupported controlled gate: control($(ctrl_loc), $(g.locs[1])=>$(typeof(g.content)))")
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
    :SX => Rx(π/2),
    :SY => Ry(π/2),
    :CNOT => control(2, 1, 2=>X),
    :CZ => control(2, 1, 2=>Z),
    :CY => control(2, 1, 2=>Y),
)

# Create the reverse mapping with proper type handling
const yao_symbol_map = Dict{Any, Symbol}(
    I2 => :I,
    X => :X,
    Y => :Y,
    Z => :Z,
    H => :H,
    S => :S,
    T => :T,
    ConstGate.CNOT => :CNOT,
    ConstGate.CZ => :CZ,
    Rx(π/2) => :SX,
    Ry(π/2) => :SY,
)
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
