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
    # Use address mapping pattern like YaoPlots: pass global addresses through recursion
    address = collect(1:nqudits(block))
    _flatten!(instructions, block, address, Int[], Int[])
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

# ============== Recursive Flattening (YaoPlots pattern) ==============

# ChainBlock: iterate over subblocks
function _flatten!(instructions::Vector{Instruction}, block::ChainBlock, 
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    for b in subblocks(block)
        _flatten!(instructions, b, address, ctrl_locs, ctrl_state)
    end
end

# PutBlock: map addresses and recurse
function _flatten!(instructions::Vector{Instruction}, block::PutBlock,
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    # Map local locations to global addresses
    locs = [address[i] for i in block.locs]
    _flatten!(instructions, content(block), locs, ctrl_locs, ctrl_state)
end

# ControlBlock: collect control info and recurse
function _flatten!(instructions::Vector{Instruction}, block::ControlBlock,
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    # Map control and target locations to global addresses
    new_ctrl_locs = [address[i] for i in block.ctrl_locs]
    new_ctrl_state = collect(block.ctrl_config)
    target_locs = [address[i] for i in block.locs]
    # Propagate controls down
    _flatten!(instructions, content(block), target_locs, 
              vcat(ctrl_locs, new_ctrl_locs), vcat(ctrl_state, new_ctrl_state))
end

# KronBlock: iterate over subblocks with their addresses
function _flatten!(instructions::Vector{Instruction}, block::KronBlock,
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    for (locs, subblock) in zip(sublocations(block), subblocks(block))
        sub_address = [address[i] for i in locs]
        _flatten!(instructions, subblock, sub_address, ctrl_locs, ctrl_state)
    end
end

# RepeatedBlock: iterate over each repetition
function _flatten!(instructions::Vector{Instruction}, block::RepeatedBlock,
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    gate = content(block)
    gate_nq = nqudits(gate)
    for locs in Iterators.partition(block.locs, gate_nq)
        sub_address = [address[i] for i in locs]
        _flatten!(instructions, gate, sub_address, ctrl_locs, ctrl_state)
    end
end

# Subroutine: unwrap and recurse with mapped addresses  
function _flatten!(instructions::Vector{Instruction}, block::Subroutine,
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    sub_address = [address[i] for i in block.locs]
    _flatten!(instructions, content(block), sub_address, ctrl_locs, ctrl_state)
end

# CachedBlock: unwrap and recurse
function _flatten!(instructions::Vector{Instruction}, block::CachedBlock,
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    _flatten!(instructions, content(block), address, ctrl_locs, ctrl_state)
end

# Scale: handle phase factor if needed
function _flatten!(instructions::Vector{Instruction}, block::Scale,
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    fp = factor(block)
    if !(abs(fp) ≈ 1)
        @warn "Scale factor $fp is not a pure phase, ignoring magnitude"
    end
    if angle(fp) != 0
        # Add global phase
        _add_instruction!(instructions, phase(angle(fp)), [address[1]] .- 1, ctrl_locs .- 1, ctrl_state)
    end
    _flatten!(instructions, content(block), address, ctrl_locs, ctrl_state)
end

# Daggered composite blocks
function _flatten!(instructions::Vector{Instruction}, block::Daggered{<:CompositeBlock},
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    # For daggered composite blocks, flatten in reverse order with daggered content
    inner = content(block)
    if inner isa ChainBlock
        for b in reverse(subblocks(inner))
            _flatten!(instructions, b', address, ctrl_locs, ctrl_state)
        end
    else
        # Fallback: compute matrix
        _add_instruction!(instructions, block, address .- 1, ctrl_locs .- 1, ctrl_state)
    end
end

# Measure: add measurement instruction
function _flatten!(instructions::Vector{Instruction}, block::Measure,
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    @assert isempty(ctrl_locs) "Controlled measurement not supported"
    if block.locations isa AllLocs
        qubits = address .- 1
    else
        qubits = [address[i] for i in block.locations] .- 1
    end
    push!(instructions, Instruction("measure", qubits))
end

# Primitive blocks: add instruction
function _flatten!(instructions::Vector{Instruction}, gate::PrimitiveBlock,
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    _add_instruction!(instructions, gate, address .- 1, ctrl_locs .- 1, ctrl_state)
end

# Fallback for other composite blocks: try to flatten subblocks or compute matrix
function _flatten!(instructions::Vector{Instruction}, block::CompositeBlock,
                   address::Vector{Int}, ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    # Try to iterate subblocks if they have matching locations
    try
        for b in subblocks(block)
            _flatten!(instructions, b, address, ctrl_locs, ctrl_state)
        end
    catch
        # Fallback: compute matrix representation
        _add_instruction!(instructions, block, address .- 1, ctrl_locs .- 1, ctrl_state)
    end
end

# ============== Add Instruction Helpers ==============

function _add_instruction!(instructions::Vector{Instruction}, gate, locs::Vector{Int},
                           ctrl_locs::Vector{Int}, ctrl_state::Vector{Int})
    name, params = _gate_to_instruction(gate)
    push!(instructions, Instruction(name, locs; params=params, ctrl=ctrl_locs, ctrl_state=ctrl_state))
end

# Gate to instruction conversion
function _gate_to_instruction(gate::ConstantGate)
    _gate_to_name(gate), Float64[]
end

function _gate_to_instruction(gate::RotationGate)
    inner = content(gate)
    base_name = _gate_to_name(inner)
    "r" * base_name, [gate.theta]
end

function _gate_to_instruction(gate::ShiftGate)
    "p", [gate.theta]
end

function _gate_to_instruction(gate::PhaseGate)
    "gphase", [gate.theta]
end

function _gate_to_instruction(gate::Daggered)
    inner = content(gate)
    if inner isa ConstantGate
        name = _gate_to_name(inner)
        if name == "s"
            return "sdg", Float64[]
        elseif name == "t"
            return "tdg", Float64[]
        end
    end
    # Fallback: compute matrix
    _gate_to_instruction_from_matrix(gate)
end

function _gate_to_instruction(gate::GeneralMatrixBlock)
    tag = gate.tag
    if tag != ""
        return tag, Float64[]
    else
        return _gate_to_instruction_from_matrix(gate)
    end
end

# FSimGate-like detection
function _gate_to_instruction(gate::PrimitiveBlock)
    if hasproperty(gate, :theta) && hasproperty(gate, :phi) && nqudits(gate) == 2
        return "fsim", [gate.theta, gate.phi]
    end
    # Fallback: serialize matrix
    _gate_to_instruction_from_matrix(gate)
end

# Fallback: serialize any block as unitary matrix
function _gate_to_instruction(block::AbstractBlock)
    _gate_to_instruction_from_matrix(block)
end

function _gate_to_instruction_from_matrix(block::AbstractBlock)
    m = mat(ComplexF64, block)
    "unitary", _serialize_matrix(m)
end

function _serialize_matrix(m::AbstractMatrix)
    # Flatten complex matrix to [re1, im1, re2, im2, ...]
    Float64[v for c in vec(m) for v in (real(c), imag(c))]
end

function _deserialize_matrix(params::Vector, nqubits::Int)
    # Reconstruct complex matrix from [re1, im1, re2, im2, ...]
    dim = 2^nqubits
    expected_len = 2 * dim * dim
    if length(params) != expected_len
        error("Invalid matrix parameters: expected $expected_len values for $nqubits qubit(s), got $(length(params))")
    end
    m = Matrix{ComplexF64}(undef, dim, dim)
    for i in 1:dim*dim
        re = params[2*i - 1]
        im = params[2*i]
        m[i] = complex(re, im)
    end
    return m
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
    elseif name == "fsim"
        # FSimGate: create matrix representation
        θ, φ = params
        fsim_mat = ComplexF64[
            1       0           0           0
            0       cos(θ)      -im*sin(θ)  0
            0       -im*sin(θ)  cos(θ)      0
            0       0           0           exp(-im*φ)
        ]
        push!(c, put(n, Tuple(qubits) => matblock(fsim_mat; tag="fsim")))
    elseif name == "unitary"
        # Custom unitary gate from serialized matrix
        m = _deserialize_matrix(params, length(qubits))
        push!(c, put(n, Tuple(qubits) => matblock(m; tag="unitary")))
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
    # Custom gates from Google Sycamore-like circuits
    elseif name == "x_1_2" || name == "x12"
        # sqrt(X) gate
        matblock(ComplexF64[1 -im; -im 1]/sqrt(2); tag="x_1_2")
    elseif name == "y_1_2" || name == "y12"
        # sqrt(Y) gate
        matblock(ComplexF64[1 -1; 1 1]/sqrt(2); tag="y_1_2")
    elseif name == "hz_1_2" || name == "hz12"
        # sqrt(Z) rotated gate
        matblock(ComplexF64[1 1+im; 1-im 1]/2; tag="hz_1_2")
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
