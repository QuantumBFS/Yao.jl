module YaoSym

using SparseArrays, LuxurySparse, LinearAlgebra
using BitBasis, YaoArrayRegister, YaoBlocks
import YaoArrayRegister: parametric_mat
using SymEngine
using SymEngine: @vars, Basic, BasicType, BasicOp, BasicTrigFunction, BasicComplexNumber

# SymEngine APIs
export @vars, Basic, subs, expand, simplify_expi

# Symbolic registers
export @ket_str, @bra_str
export SymReg, AdjointSymReg, SymRegOrAdjointSymReg
export szero_state

include("register.jl")
include("symengine/symengine.jl")

end # module
