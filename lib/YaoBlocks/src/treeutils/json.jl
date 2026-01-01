"""
JSON-based quantum circuit serialization format.

This module provides a generic instruction-based JSON format for quantum circuits
that is independent of YaoBlocks' internal representation. The format is designed
to be easily transpilable to OpenQASM and other quantum assembly languages.

## JSON Format

```json
{
  "version": "1.0",
  "nqubits": 5,
  "instructions": [
    {"name": "h", "qubits": [0]},
    {"name": "cx", "qubits": [0, 1]},
    {"name": "rx", "qubits": [2], "params": [0.5]},
    {"name": "measure", "qubits": [0, 1, 2]}
  ]
}
```

## Supported Instructions

### Single-qubit gates
- `x`, `y`, `z`, `h`, `s`, `t`, `sdg`, `tdg`, `id`
- `rx`, `ry`, `rz` (with params)
- `p` (phase gate, with params)
- `u1`, `u2`, `u3` (with params)

### Two-qubit gates
- `cx`, `cy`, `cz`, `ch` (controlled gates)
- `swap`
- `rxx`, `ryy`, `rzz` (with params)

### Multi-qubit gates
- `ccx` (Toffoli)
- `cswap` (Fredkin)

### Measurement
- `measure`

### Control modifier
- Any gate can have `ctrl` and `ctrl_state` fields for controlled versions
"""

"""
    Instruction

Represents a single quantum instruction in the JSON format.
"""
struct Instruction
    name::String
    qubits::Vector{Int}
    params::Vector{Float64}
    ctrl::Vector{Int}
    ctrl_state::Vector{Int}
end

function Instruction(name::String, qubits::Vector{Int}; 
                     params::Vector{Float64}=Float64[], 
                     ctrl::Vector{Int}=Int[], 
                     ctrl_state::Vector{Int}=Int[])
    Instruction(name, qubits, params, ctrl, ctrl_state)
end

"""
    Circuit

Represents a quantum circuit in the JSON format.
"""
struct Circuit
    version::String
    nqubits::Int
    instructions::Vector{Instruction}
end

Circuit(nqubits::Int, instructions::Vector{Instruction}) = Circuit("1.0", nqubits, instructions)

# ============== Block to JSON ==============

"""
    circuit_to_json_dict(block::AbstractBlock) -> Dict

Convert a YaoBlocks circuit to a JSON-serializable dictionary in the instruction format.
"""
function circuit_to_json_dict(block::AbstractBlock)
    instructions = Instruction[]
    _flatten_to_instructions!(instructions, block)
    Dict(
        "version" => "1.0",
        "nqubits" => nqudits(block),
        "instructions" => [_instruction_to_dict(inst) for inst in instructions]
    )
end

function _instruction_to_dict(inst::Instruction)
    d = Dict{String,Any}(
        "name" => inst.name,
        "qubits" => inst.qubits  # 0-indexed for OpenQASM compatibility
    )
    if !isempty(inst.params)
        d["params"] = inst.params
    end
    if !isempty(inst.ctrl)
        d["ctrl"] = inst.ctrl
        d["ctrl_state"] = inst.ctrl_state
    end
    return d
end

# Flatten a block tree to a list of instructions
function _flatten_to_instructions!(instructions::Vector{Instruction}, block::ChainBlock)
    for b in subblocks(block)
        _flatten_to_instructions!(instructions, b)
    end
end

function _flatten_to_instructions!(instructions::Vector{Instruction}, block::PutBlock)
    locs = collect(block.locs) .- 1  # Convert to 0-indexed
    _add_gate_instruction!(instructions, content(block), locs)
end

function _flatten_to_instructions!(instructions::Vector{Instruction}, block::ControlBlock)
    locs = collect(block.locs) .- 1
    ctrl_locs = collect(block.ctrl_locs) .- 1
    ctrl_state = collect(block.ctrl_config)
    _add_controlled_instruction!(instructions, content(block), locs, ctrl_locs, ctrl_state)
end

function _flatten_to_instructions!(instructions::Vector{Instruction}, block::Measure)
    if block.locations isa AllLocs
        qubits = collect(0:block.n-1)
    else
        qubits = collect(block.locations) .- 1
    end
    push!(instructions, Instruction("measure", qubits))
end

function _flatten_to_instructions!(instructions::Vector{Instruction}, block::AbstractBlock)
    error("Unsupported block type for JSON serialization: $(typeof(block)). " *
          "Consider using `Optimise.to_basictypes(circuit)` to simplify the circuit first.")
end

# Add a gate instruction (handles primitives)
function _add_gate_instruction!(instructions::Vector{Instruction}, gate::ConstantGate, locs::Vector{Int})
    name = _gate_to_name(gate)
    push!(instructions, Instruction(name, locs))
end

function _add_gate_instruction!(instructions::Vector{Instruction}, gate::RotationGate, locs::Vector{Int})
    inner = content(gate)
    base_name = _gate_to_name(inner)
    name = "r" * base_name
    push!(instructions, Instruction(name, locs; params=[gate.theta]))
end

function _add_gate_instruction!(instructions::Vector{Instruction}, gate::ShiftGate, locs::Vector{Int})
    push!(instructions, Instruction("p", locs; params=[gate.theta]))
end

function _add_gate_instruction!(instructions::Vector{Instruction}, gate::PhaseGate, locs::Vector{Int})
    push!(instructions, Instruction("gphase", locs; params=[gate.theta]))
end

function _add_gate_instruction!(instructions::Vector{Instruction}, gate::Daggered, locs::Vector{Int})
    # For daggered gates, we need to handle them specially
    inner = content(gate)
    if inner isa ConstantGate
        name = _gate_to_name(inner)
        if name == "s"
            push!(instructions, Instruction("sdg", locs))
        elseif name == "t"
            push!(instructions, Instruction("tdg", locs))
        else
            error("Daggered gate '$name' not directly supported. Use Optimise.to_basictypes first.")
        end
    else
        error("Daggered non-constant gate not supported. Use Optimise.to_basictypes first.")
    end
end

function _add_gate_instruction!(instructions::Vector{Instruction}, gate::AbstractBlock, locs::Vector{Int})
    error("Unsupported gate type for JSON: $(typeof(gate)). Use Optimise.to_basictypes first.")
end

# Add a controlled instruction
function _add_controlled_instruction!(instructions::Vector{Instruction}, gate, locs::Vector{Int}, 
                                      ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    # For common controlled gates, use standard names
    if length(ctrl_locs) == 1 && ctrl_state[1] == 1 && gate isa ConstantGate
        base_name = _gate_to_name(gate)
        if base_name in ["x", "y", "z", "h"]
            push!(instructions, Instruction("c" * base_name, vcat(ctrl_locs, locs)))
            return
        end
    end
    if length(ctrl_locs) == 2 && all(==(1), ctrl_state) && gate isa XGate
        push!(instructions, Instruction("ccx", vcat(ctrl_locs, locs)))
        return
    end
    
    # General controlled gate with ctrl modifier
    if gate isa ConstantGate
        name = _gate_to_name(gate)
        push!(instructions, Instruction(name, locs; ctrl=ctrl_locs, ctrl_state=ctrl_state))
    elseif gate isa RotationGate
        inner = content(gate)
        base_name = _gate_to_name(inner)
        name = "r" * base_name
        push!(instructions, Instruction(name, locs; params=[gate.theta], ctrl=ctrl_locs, ctrl_state=ctrl_state))
    elseif gate isa ShiftGate
        push!(instructions, Instruction("p", locs; params=[gate.theta], ctrl=ctrl_locs, ctrl_state=ctrl_state))
    else
        error("Unsupported controlled gate type: $(typeof(gate))")
    end
end

# Map gate types to instruction names
function _gate_to_name(gate::ConstantGate)
    T = typeof(gate)
    name = string(T.name.name)
    if endswith(name, "Gate")
        name = name[1:end-4]
    end
    lowercase(name)
end

_gate_to_name(::XGate) = "x"
_gate_to_name(::YGate) = "y"
_gate_to_name(::ZGate) = "z"
_gate_to_name(::HGate) = "h"
_gate_to_name(::I2Gate) = "id"
_gate_to_name(::TGate) = "t"
_gate_to_name(::SWAPGate) = "swap"

# S gate handling - need to check if it exists
if @isdefined(SGate)
    _gate_to_name(::SGate) = "s"
end
if @isdefined(SdagGate)
    _gate_to_name(::SdagGate) = "sdg"
end
if @isdefined(TdagGate)
    _gate_to_name(::TdagGate) = "tdg"
end

# ============== JSON to Block ==============

"""
    circuit_from_json(json_str::String) -> ChainBlock

Parse a JSON string in the instruction format to a YaoBlocks circuit.
"""
function circuit_from_json(json_str::String)
    d = JSON.parse(json_str; dicttype=Dict{String,Any})
    circuit_from_json_dict(d)
end

"""
    circuit_from_json_dict(d::Dict) -> ChainBlock

Convert a dictionary (parsed from JSON) to a YaoBlocks circuit.
"""
function circuit_from_json_dict(d::Dict)
    nqubits = d["nqubits"]
    instructions = d["instructions"]
    
    c = chain(nqubits)
    for inst in instructions
        _add_instruction_to_chain!(c, inst)
    end
    return c
end

function _add_instruction_to_chain!(c::ChainBlock, inst::Dict)
    name = inst["name"]
    qubits = inst["qubits"] .+ 1  # Convert to 1-indexed
    params = get(inst, "params", Float64[])
    ctrl = get(inst, "ctrl", Int[])
    ctrl_state = get(inst, "ctrl_state", Int[])
    
    n = nqudits(c)
    
    if !isempty(ctrl)
        # Controlled gate
        ctrl_1indexed = ctrl .+ 1
        # Reconstruct signed ctrl_locs
        signed_ctrl = [loc * (2 * cfg - 1) for (loc, cfg) in zip(ctrl_1indexed, ctrl_state)]
        gate = _name_to_gate(name, params)
        push!(c, control(n, Tuple(signed_ctrl), Tuple(qubits) => gate))
    elseif name == "measure"
        push!(c, Measure(n; locs=Tuple(qubits)))
    elseif name in ["cx", "cy", "cz", "ch"]
        # Standard controlled gates
        base_name = name[2:end]
        gate = _name_to_gate(base_name, Float64[])
        push!(c, control(n, qubits[1], qubits[2] => gate))
    elseif name == "ccx"
        push!(c, control(n, (qubits[1], qubits[2]), qubits[3] => X))
    elseif name == "swap"
        push!(c, swap(n, qubits[1], qubits[2]))
    else
        gate = _name_to_gate(name, params)
        if length(qubits) == 1
            push!(c, put(n, qubits[1] => gate))
        else
            push!(c, put(n, Tuple(qubits) => gate))
        end
    end
end

function _name_to_gate(name::String, params::Vector)
    if name == "x"
        X
    elseif name == "y"
        Y
    elseif name == "z"
        Z
    elseif name == "h"
        H
    elseif name == "id"
        I2
    elseif name == "s"
        ConstGate.S
    elseif name == "t"
        T
    elseif name == "sdg"
        ConstGate.Sdag
    elseif name == "tdg"
        ConstGate.Tdag
    elseif name == "rx"
        Rx(params[1])
    elseif name == "ry"
        Ry(params[1])
    elseif name == "rz"
        Rz(params[1])
    elseif name == "p"
        shift(params[1])
    elseif name == "gphase"
        phase(params[1])
    elseif name == "u1"
        shift(params[1])
    elseif name == "u2"
        ϕ, λ = params
        matblock(ComplexF64[1 -exp(im*λ); exp(im*ϕ) exp(im*(ϕ+λ))] / sqrt(2); tag="u2")
    elseif name == "u3"
        θ, ϕ, λ = params
        matblock(ComplexF64[cos(θ/2) -exp(im*λ)*sin(θ/2); exp(im*ϕ)*sin(θ/2) exp(im*(ϕ+λ))*cos(θ/2)]; tag="u3")
    elseif name == "swap"
        SWAP
    else
        error("Unknown gate name: $name")
    end
end

# ============== File I/O ==============

"""
    json_to_file(filename::String, block::AbstractBlock)

Save a quantum circuit to a JSON file in the instruction format.
"""
function json_to_file(filename::String, block::AbstractBlock)
    open(filename, "w") do io
        JSON.print(io, circuit_to_json_dict(block), 2)
    end
end

"""
    json_from_file(filename::String) -> ChainBlock

Load a quantum circuit from a JSON file.
"""
function json_from_file(filename::String)
    d = JSON.parsefile(filename; dicttype=Dict{String,Any})
    circuit_from_json_dict(d)
end

"""
    check_json_roundtrip(gate::AbstractBlock) -> Bool

Check that a gate can be serialized to JSON and deserialized correctly.
"""
function check_json_roundtrip(gate::AbstractBlock)
    d = circuit_to_json_dict(gate)
    gate2 = circuit_from_json_dict(d)
    mat(gate2) ≈ mat(gate)
end
