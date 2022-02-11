"""
Base module for Yao.
"""
module YaoBase

using LinearAlgebra, LuxurySparse, SparseArrays, Random
using Reexport

@reexport using YaoAPI
using YaoAPI

import YaoAPI:
    isunitary,
    isreflexive,
    iscommute,
    AbstractRegister,
    AdjointRegister,
    AbstractBlock,
    PostProcess,
    NotImplementedError,
    LocationConflictError,
    QubitMismatchError,
    instruct!,
    focus!,
    relax!,
    nqudits,
    nqubits,
    nremain,
    nactive,
    nbatch,
    viewbatch,
    addbits!,
    insert_qudits!,
    measure,
    measure!,
    occupied_locs,
    invorder!,
    partial_tr,
    select!,
    ρ,
    reorder!,
    nlevel
export basis, ishermitian

include("utils/ast_tools.jl")

include("utils/constants.jl")
include("utils/math.jl")

include("error.jl")
include("abstract_register.jl")
include("adjoint_register.jl")

include("inspect.jl")
include("instruct.jl")

# compat with older version of dependencies
include("compat.jl")

# deprecation warns
include("deprecations.jl")

end # module
