module OpenQASMExt

using YaoBlocks
using YaoBlocks: AbstractBlock, CompositeBlock, PrimitiveBlock, PutBlock, ControlBlock, ChainBlock
using YaoBlocks: Daggered, GeneralMatrixBlock, RotationGate, ShiftGate, PhaseGate, KronBlock
using YaoBlocks: XGate, YGate, ZGate, HGate, I2Gate, TGate, SWAPGate
using YaoBlocks: ConstGate, Measure, AllLocs
using YaoBlocks: content, subblocks, nqubits, nqudits, getiparams
using YaoBlocks: put, control, chain, swap, rot, kron, shift, matblock
using YaoBlocks: X, Y, Z, H, I2, T, Rx, Ry, Rz
using YaoBlocks: Optimise
using YaoBlocks: AbstractErrorType, DepolarizingError, ThermalRelaxationError, CoherentError
using YaoBlocks: PauliError, AmplitudeDampingError, PhaseDampingError, PhaseAmplitudeDampingError

import YaoBlocks: KrausChannel, quantum_channel

using OpenQASM
using OpenQASM.RBNF: Token

include("compile.jl")
include("parse.jl")

end # module
