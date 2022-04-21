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
    rand_state,
    uniform_state,
    oneto,
    # additional
    state,
    statevec,
    relaxedvec,
    rank3

# BitBasis
export @bit_str, hypercubic

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
    collapseto!,
    density_matrix,
    von_neumann_entropy,
    mutual_information,
    fidelity,
    focus!,
    insert_qudits!,
    insert_qubits!,
    most_probable,
    instruct!,
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
    ρ,
    basis

# others
export Const, logdi

include("ast_tools.jl")
include("constants.jl")
include("utils.jl")
include("register.jl")
include("operations.jl")
include("focus.jl")

include("instruct.jl")

include("density_matrix.jl")
include("measure.jl")

include("deprecations.jl")

end # module
