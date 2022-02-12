"""
YaoArrayRegister.jl is a component package in the [Yao.jl](https://github.com/QuantumBFS/Yao.jl) ecosystem.
It provides the most basic functionality for quantum
computation simulation in Julia and a quantum register type `ArrayReg`. You will be
able to simulate a quantum circuit alone with this package in principle.
"""
module YaoArrayRegister

using Adapt
using YaoBase
using BitBasis
using LinearAlgebra

export ArrayReg,
    AdjointArrayReg,
    ArrayRegOrAdjointArrayReg,
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

# YaoBase
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
    addbits!,
    collapseto!,
    density_matrix,
    von_neumann_entropy,
    mutual_information,
    fidelity,
    focus!,
    insert_qudits!,
    instruct!,
    invorder!,
    measure,
    measure!,
    nactive,
    nbatch,
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


include("utils.jl")
include("register.jl")
include("operations.jl")
include("focus.jl")

include("instruct.jl")

include("density_matrix.jl")
include("measure.jl")

include("deprecations.jl")

end # module
