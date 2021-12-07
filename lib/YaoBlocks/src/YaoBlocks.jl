"""
Standard basic quantum circuit simulator building blocks.

This is a component package for [Yao.jl](https://github.com/QuantumBFS/Yao.jl). It contains the abstract definitions and basic implementation of Yao's circuit building blocks.
"""
module YaoBlocks

using YaoBase
using LinearAlgebra

import YaoBase:
    apply!,
    apply_back!,
    chcontent,
    chsubblocks,
    content,
    dispatch!,
    expect,
    fidelity,
    focus!,
    getiparams,
    iparams_eltype,
    iscommute,
    isreflexive,
    isunitary,
    mat,
    mat_back!,
    niparams,
    nqubits,
    occupied_locs,
    operator_fidelity,
    parameters,
    parameters_eltype,
    print_block,
    render_params,
    setiparams!,
    subblocks,
    ishermitian,
    nparameters

export AbstractBlock,
    AbstractContainer,
    CompositeBlock,
    LocationConflictError,
    PrimitiveBlock,
    QubitMismatchError,
    RemoveMeasured,
    ResetTo,
    TagBlock,
    apply!,
    apply,
    apply_back!,
    chcontent,
    chsubblocks,
    content,
    dispatch!,
    dispatch,
    expect,
    getiparams,
    iparams_eltype,
    iscommute,
    isreflexive,
    isunitary,
    mat,
    mat_back!,
    niparams,
    nqubits,
    occupied_locs,
    operator_fidelity,
    parameters,
    parameters_eltype,
    print_block,
    render_params,
    setiparams!,
    setiparams,
    subblocks,
    ishermitian,
    nparameters

export applymatrix, cache_key

include("utils.jl")
# include("traits.jl")

include("abstract_block.jl")

# concrete blocks
include("routines.jl")
include("primitive/primitive.jl")
include("composite/composite.jl")

include("algebra.jl")
include("blocktools.jl")
include("measure_ops.jl")
include("layout.jl")
include("treeutils/treeutils.jl")

include("autodiff/autodiff.jl")
export AD, Optimise

include("deprecations.jl")

end # YaoBlocks
