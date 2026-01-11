"""
    QASMIOContext{IOT} <: IO

An IO context for QASM output.

# Fields
- `io::IOT`: the underlying IO object
- `current_qubits::Vector{Int}`: the current qubit indices
"""
mutable struct QASMIOContext{IOT} <: IO
    const io::IOT
    current_qubits::Vector{Int}
end

for T in [SubString{String}, String, Symbol, Any]
    @eval Base.print(io::QASMIOContext, str::$T) = print(io.io, str)
end

function Base.show(io::QASMIOContext, ::MIME"qasm/open", blk::AbstractBlock)
    println(io, blk)
end

"""
    qasm(block::AbstractBlock; include_header::Bool=false) -> String

Convert a YaoBlocks circuit to an OpenQASM string. The output uses OpenQASM 3.0 syntax
(e.g., `ctrl @`, `negctrl @`, `inv @` modifiers) while maintaining compatibility with
common OpenQASM 2.0 gate definitions through `qelib1.inc`.

# Arguments
- `block::AbstractBlock`: The quantum circuit block to convert
- `include_header::Bool=false`: Whether to include the QASM header with version, 
  include statement, and qubit register declaration

# Returns
- `String`: The OpenQASM representation of the circuit

# Supported Blocks
- **Primitive gates**: `I2`, `X`, `Y`, `Z`, `H`, `S`, `Sdag`, `T`, `Tdag`
- **Rotation gates**: `Rx`, `Ry`, `Rz` (→ `rx`, `ry`, `rz`)
- **Phase gate**: `shift` (→ `p`)
- **Composite blocks**: `PutBlock`, `ControlBlock`, `ChainBlock`
- **Modifiers**: `Daggered` (→ `inv @`)
- **Custom gates**: `GeneralMatrixBlock` with tag (outputs the tag name)

# Notes
- Qubit indices in QASM are 0-based, while YaoBlocks uses 1-based indexing
- For unsupported blocks, consider using `YaoBlocks.Optimise.to_basictypes` first
- Parsing via `parseblock` supports both OpenQASM 2.0 and 3.0 inputs

# Examples

```jldoctest; setup=:(using Yao)
julia> qasm(put(2, 1=>X))
"x q[0]"

julia> qasm(control(2, 1, 2=>X))
"cx q[0], q[1]"

julia> qasm(chain(put(2, 1=>H), control(1, 2=>X)); include_header=true)
"OPENQASM 2.0;\\ninclude \\"qelib1.inc\\";\\nqreg q[2];\\ncreg c[2];\\nh q[0];\\ncx q[0], q[1];\\n"
```

See also: [`parseblock`](@ref)
"""
function qasm(block::AbstractBlock; include_header::Bool=false)
    io = QASMIOContext(IOBuffer(), [1:nqudits(block)...])
    include_header && println(io, """OPENQASM 2.0;
include "qelib1.inc";
qreg q[$(nqubits(block))];
creg c[$(nqubits(block))];""")
    print_qasm(io, block)
    String(take!(io.io))
end

######################## Basic Buiding Blocks ########################

# -> composite blocks
function print_qasm(io::QASMIOContext, blk::PutBlock{D,M,GT}) where {D, M, GT <: PrimitiveBlock}
    print_qasm(io, content(blk))
    print(io, " ")
    print_addrs(io, blk.locs)
end

function print_qasm(io::QASMIOContext, blk::ControlBlock{GT}) where GT <: PrimitiveBlock
    # Use QASM 2.0 compatible syntax for common controlled gates
    ctrl_locs = blk.ctrl_locs
    target_locs = blk.locs
    ctrl_config = blk.ctrl_config
    gate = content(blk)

    # Single positive control - use QASM 2.0 gates
    if length(ctrl_locs) == 1 && ctrl_config[1] == 1
        if gate isa XGate
            print(io, "cx ")
        elseif gate isa YGate
            print(io, "cy ")
        elseif gate isa ZGate
            print(io, "cz ")
        elseif gate isa HGate
            print(io, "ch ")
        elseif gate isa ShiftGate
            print(io, "cu1")
            print_params(io, getiparams(gate))
            print(io, " ")
        elseif gate isa RotationGate{2, T, ZGate} where T
            print(io, "crz")
            print_params(io, getiparams(gate))
            print(io, " ")
        else
            # Fallback to QASM 3.0 syntax
            print(io, "ctrl @ ")
            print_qasm(io, gate)
            print(io, " ")
        end
        print_addrs(io, (ctrl_locs..., target_locs...))
    # Double positive control for X gate (Toffoli)
    elseif length(ctrl_locs) == 2 && all(==(1), ctrl_config) && gate isa XGate
        print(io, "ccx ")
        print_addrs(io, (ctrl_locs..., target_locs...))
    else
        # Fallback to QASM 3.0 syntax for complex cases
        for c in ctrl_config
            print(io, c == 1 ? "ctrl @ " : "negctrl @ ")
        end
        print_qasm(io, gate)
        print(io, " ")
        print_addrs(io, (ctrl_locs..., target_locs...))
    end
end

function print_qasm(io::QASMIOContext, blk::ChainBlock)
    for (k, b) in enumerate(subblocks(blk))
        @assert b isa CompositeBlock "primitive gate in chain block should be a composite block."
        print_qasm(io, b)
        # Don't add semicolon after nested ChainBlocks (they handle their own semicolons)
        if !(b isa ChainBlock)
            println(io, ";")
        end
    end
end

function print_qasm(io::QASMIOContext, blk::Daggered)
    print(io, "inv @ ")
    print_qasm(io, content(blk))
end

# -> Primitive blocks
function print_qasm(io::QASMIOContext, blk::GeneralMatrixBlock)
    tag_str = string(blk.tag)
    if isempty(tag_str)
        error("GeneralMatrixBlock has empty tag; cannot emit valid OpenQASM output. Set a tag with `matblock(matrix; tag=\"name\")`.")
    end
    print(io, tag_str)
end

# x, y, z, h, s, sdag, t, tdag
print_qasm(io::QASMIOContext, ::I2Gate) = print(io, "id")
print_qasm(io::QASMIOContext, ::XGate) = print(io, "x")
print_qasm(io::QASMIOContext, ::YGate) = print(io, "y")
print_qasm(io::QASMIOContext, ::ZGate) = print(io, "z")
print_qasm(io::QASMIOContext, ::HGate) = print(io, "h")
print_qasm(io::QASMIOContext, ::ConstGate.SGate) = print(io, "s")
print_qasm(io::QASMIOContext, ::TGate) = print(io, "t")
print_qasm(io::QASMIOContext, ::ConstGate.SdagGate) = print(io, "inv @ s")
print_qasm(io::QASMIOContext, ::ConstGate.TdagGate) = print(io, "inv @ t")

# rx, ry, rz
function print_qasm(io::QASMIOContext, blk::RotationGate{2, T, <:PrimitiveBlock}) where T
    print(io, "r")
    print_qasm(io, content(blk))
    print_params(io, getiparams(blk))
end

# p (phase gate)
function print_qasm(io::QASMIOContext, blk::ShiftGate) 
    print(io, "p")
    print_params(io, getiparams(blk))
end

# Fallback for unsupported blocks
function print_qasm(io::QASMIOContext, blk::AbstractBlock)
    error("block type not supported for QASM output, got: $blk. Try simplifying the circuit with the `YaoBlocks.Optimise.to_basictypes` function.")
end

# HELPERS
function print_addrs(io::QASMIOContext, locs)
    for (k, i) in enumerate(locs)
        print(io, "q[$(i-1)]")
        k != length(locs) && print(io, ", ")
    end
end

function print_params(io::QASMIOContext, params)
    print(io, "(")
    for (k, p) in enumerate(params)
        print(io, p)
        k != length(params) && print(io, ", ")
    end
    print(io, ")")
end
