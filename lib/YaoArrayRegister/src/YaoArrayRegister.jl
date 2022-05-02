"""
YaoArrayRegister.jl is a component package in the [Yao.jl](https://github.com/QuantumBFS/Yao.jl) ecosystem.
It provides the most basic functionality for quantum
computation simulation in Julia and a quantum register type `ArrayReg`. You will be
able to simulate a quantum circuit alone with this package in principle.
"""
module YaoArrayRegister

using Adapt
using YaoAPI
using BitBasis
using LinearAlgebra
using LegibleLambdas
using StatsBase, Random
using LuxurySparse, StaticArrays

export AbstractArrayReg,
    ArrayReg,
    BatchedArrayReg,
    AdjointArrayReg,
    ArrayRegOrAdjointArrayReg,
    NoBatch,
    arrayreg,
    transpose_storage,
    datatype,
    # initialization
    product_state,
    zero_state,
    zero_state_like,
    rand_state,
    ghz_state,
    uniform_state,
    oneto,
    # additional
    state,
    statevec,
    relaxedvec,
    rank3,
    # operations
    isnormalized,
    normalize!,
    norm,
    regadd!,
    regsub!,
    regscale!,
    exchange_sysenv,
    print_table

# BitBasis
export @bit_str, @dit_str, BitStr, DitStr, hypercubic

# YaoAPI
export AbstractRegister,
    AdjointRegister,
    AllLocs,
    ComputationalBasis,
    DensityMatrix,
    LocationConflictError,
    NoPostProcess,
    NotImplementedError,
    PostProcess,
    QubitMismatchError,
    RemoveMeasured,
    ResetTo,
    append_qudits!,
    append_qubits!,
    collapseto!,
    density_matrix,
    von_neumann_entropy,
    mutual_information,
    fidelity,
    focus!,
    focus,
    insert_qudits!,
    insert_qubits!,
    most_probable,
    instruct!,
    accum_instruct!,
    invorder!,
    measure,
    measure!,
    nactive,
    nbatch,
    nlevel,
    nqubits,
    nqudits,
    nremain,
    partial_tr,
    probs,
    purify,
    relax!,
    reorder!,
    select,
    select!,
    tracedist,
    viewbatch,
    basis,
    clone

# matrix types
export IMatrix, PermMatrix, Diagonal, SparseMatrixCSC

# others
export Const, logdi

include("ast_tools.jl")
include("constants.jl")
include("utils.jl")
include("register.jl")
include("operations.jl")
include("focus.jl")

include("instruct.jl")
include("qudit_instruct.jl")

include("density_matrix.jl")
include("measure.jl")

include("deprecations.jl")

end # module
