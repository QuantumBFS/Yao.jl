"""
    QASMIOContext{IOT} <: IO

An IO context for QASM output.

# Fields
- `io::IOT`: the underlying IO object
"""
struct QASMIOContext{IOT} <: IO
    io::IOT
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
- Circuits are automatically simplified using `Optimise.canonicalize` before compilation
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
    # Recursively simplify circuit before compiling: eliminate nested blocks and convert to basic types
    block = Optimise.canonicalize(block)

    io = QASMIOContext(IOBuffer())
    include_header && println(io, """OPENQASM 2.0;
include "qelib1.inc";
qreg q[$(nqubits(block))];
creg c[$(nqubits(block))];""")
    print_qasm(io, block)
    String(take!(io.io))
end

######################## Basic Building Blocks ########################

# -> composite blocks
function print_qasm(io::QASMIOContext, blk::PutBlock{D,M,GT}) where {D, M, GT <: PrimitiveBlock}
    # Skip global phase gates as they don't affect measurement outcomes
    content(blk) isa PhaseGate && return nothing
    print_qasm(io, content(blk))
    print(io, " ")
    print_addrs(io, blk.locs)
end

# Handle PutBlock with ControlBlock content - need to remap qubit locations
function print_qasm(io::QASMIOContext, blk::PutBlock{D,M,GT}) where {D, M, GT <: ControlBlock}
    ctrl_blk = content(blk)
    locs = blk.locs
    # Map the control and target locations from the inner system to the outer system
    ctrl_locs = Tuple(locs[i] for i in ctrl_blk.ctrl_locs)
    target_locs = Tuple(locs[i] for i in ctrl_blk.locs)
    ctrl_config = ctrl_blk.ctrl_config
    gate = content(ctrl_blk)

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
    for b in subblocks(blk)
        @assert b isa CompositeBlock "primitive gate in chain block should be a composite block."
        # Skip global phase gates as they don't produce QASM output
        _is_global_phase(b) && continue
        print_qasm(io, b)
        println(io, ";")
    end
end

# Check if a block is a global phase (doesn't affect measurement outcomes)
_is_global_phase(::AbstractBlock) = false
_is_global_phase(blk::PutBlock) = content(blk) isa PhaseGate

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

# swap gate
print_qasm(io::QASMIOContext, ::SWAPGate) = print(io, "swap")

# rzz gate - rotation around ZZ
function print_qasm(io::QASMIOContext, blk::RotationGate{2, T, <:KronBlock}) where T
    kb = content(blk)
    # Check if this is a ZZ rotation (kron(Z, Z))
    subs = subblocks(kb)
    if length(subs) == 2 && subs[1] isa ZGate && subs[2] isa ZGate
        print(io, "rzz")
        print_params(io, getiparams(blk))
    else
        error("Only ZZ rotation (rzz) is supported for KronBlock rotation, got: $blk")
    end
end

# PhaseGate (global phase) - ignore in QASM output as it doesn't affect measurement outcomes
print_qasm(io::QASMIOContext, ::PhaseGate) = nothing

# Fallback for unsupported blocks
function print_qasm(io::QASMIOContext, blk::AbstractBlock)
    error("block type not supported for QASM output, got: $blk")
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
