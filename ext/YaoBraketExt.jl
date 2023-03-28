module YaoBraketExt

export generate_inst, convert_to_braket

using YaoBlocks
using Braket

"""
    convert_to_braket(qc)

Convert an `AbstractBlock` in Yao to a `Circuit` in Braket.

- `qc`: An `AbstractBlock` (typically a `ChainBlock`), i.e., circuit that is to be converted.
"""
function convert_to_braket(qc::AbstractBlock{N}) where {N}
    inst = generate_inst(qc)
    return Circuit(inst)
end

"""
    generate_inst(qc)

Parses the YaoIR into a list of Braket supported instructions.

- `qc`: An `AbstractBlock` (typically a `ChainBlock`), i.e., circuit that is to be run.
"""
function generate_inst(qc::AbstractBlock{N}) where {N}
    inst = []
    generate_inst!(inst, basicstyle(qc), [0:N...], Int[])
    return inst
end

function generate_inst!(inst, qc_simpl::ChainBlock, locs, controls)
    for block in subblocks(qc_simpl)
        generate_inst!(inst, block, locs, controls)
    end
end

function generate_inst!(inst, blk::PutBlock{N,M}, locs, controls) where {N,M}
    generate_inst!(inst, blk.content, sublocs(blk.locs, locs), controls)
end

function generate_inst!(inst, blk::ControlBlock{N,GT,C}, locs, controls) where {N,GT,C}
    any(==(0), blk.ctrl_config) && error("Inverse Control used in Control gate context.")
    generate_inst!(
        inst,
        blk.content,
        sublocs(blk.locs, locs),
        [controls..., sublocs(blk.ctrl_locs, locs)...],
    )
end

function generate_inst!(inst, m::YaoBlocks.Measure{N}, locs, controls) where {N}
    mlocs = sublocs(m.locations isa AllLocs ? [1:N...] : [m.locations...], locs)
    (m.operator isa ComputationalBasis) ||
        error("Measuring an operator is not yet supported.")
    (length(controls) == 0) || error("Controlled measure is not yet supported.")
    push!(inst, (Braket.Probability, mlocs))
end

# General unitary gates
function generate_inst!(
    inst,
    gate::GeneralMatrixBlock{N,C,MT},
    locs,
    controls,
) where {N,C,MT}
    (length(controls) == 0) ||
        error("Controlled version of general unitary is not yet supported.")
    push!(inst, (Braket.Unitary, [locs...], gate.mat))
end

# Primitive cosntant gates
for (GT, BKG, MAXC) in [
    (:XGate, Braket.X, 2),
    (:YGate, Braket.Y, 1),
    (:ZGate, Braket.Z, 1),
    (:I2Gate, Braket.I, 0),
    (:HGate, Braket.H, 0),
    (:TGate, Braket.T, 0),
    (:SWAPGate, Braket.Swap, 1),
]
    @eval function generate_inst!(inst, gate::$GT, locs, controls)
        if length(controls) <= $MAXC
            if length(controls) == 0
                braket_gate = $BKG
            elseif length(controls) == 1
                braket_gate = (
                    typeof(gate) == YaoBlocks.XGate ? Braket.CNot :
                    typeof(gate) == YaoBlocks.YGate ? Braket.CY :
                    typeof(gate) == YaoBlocks.ZGate ? Braket.CZ : Braket.CSwap
                )
            else
                braket_gate = Braket.CCNot
            end
            push!(inst, (braket_gate, [controls..., locs...]))
        else
            error("Too many control bits!")
        end
    end
end

# Rotation gates
for (GT, BKG, PARAMS, MAXC) in [
    (:(RotationGate{2,T,XGate} where {T}), Braket.Rx, :(b.theta), 0),
    (:(RotationGate{2,T,YGate} where {T}), Braket.Ry, :(b.theta), 0),
    (:(RotationGate{2,T,ZGate} where {T}), Braket.Rz, :(b.theta), 0),
    (:(ShiftGate), Braket.PhaseShift, :(b.theta), 1),
]
    @eval function generate_inst!(inst, b::$GT, locs, controls)
        if length(controls) <= $MAXC
            if length(controls) == 0
                braket_gate = $BKG
            else
                braket_gate = Braket.CPhaseShift
            end
            push!(inst, (braket_gate, [controls..., locs...], $PARAMS))
        else
            error("Too many control bits! Got $controls (length > $($(MAXC)))")
        end
    end
end

sublocs(subs, locs) = [locs[i] for i in subs]

function basicstyle(blk::AbstractBlock)
    YaoBlocks.Optimise.simplify(blk, rules = [YaoBlocks.Optimise.to_basictypes])
end

end