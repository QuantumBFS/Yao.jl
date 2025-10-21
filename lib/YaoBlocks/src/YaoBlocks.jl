"""
Standard basic quantum circuit simulator building blocks.

This is a component package for [Yao.jl](https://github.com/QuantumBFS/Yao.jl). It contains the abstract definitions and basic implementation of Yao's circuit building blocks.
"""
module YaoBlocks

using YaoAPI
using LinearAlgebra
using YaoArrayRegister
using YaoArrayRegister: @λ, matvec, diff, autostatic, rot_mat
using BitBasis, LuxurySparse, SparseArrays
using LuxurySparse: fastkron
using StatsBase, TupleTools, InteractiveUtils
using MLStyle: @match
using LinearAlgebra: eigen!
using Random, CacheServers
import KrylovKit: exponentiate
using DocStringExtensions
import StaticArrays: SMatrix

import YaoAPI:
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
    isdiagonal,
    mat,
    mat_back!,
    niparams,
    nqubits,
    nqudits,
    nlevel,
    occupied_locs,
    operator_fidelity,
    parameters,
    parameters_eltype,
    print_block,
    render_params,
    setiparams!,
    subblocks,
    nparameters,
    measure!,
    measure,
    apply_back!,
    mat_back!

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
    sandwich,
    expect,
    getiparams,
    iparams_eltype,
    iscommute,
    isreflexive,
    isunitary,
    isdiagonal,
    isnoisy,
    mat,
    mat_back!,
    niparams,
    nqubits,
    nqudits,
    nlevel,
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
    nparameters,
    rand_unitary,
    rand_hermitian,
    EntryTable,
    cleanup,
    isclean,
    canonicalize,
    AbstractYaoBackend,
    YaoBackend,
    PauliPropagationBackend
export applymatrix, cache_key

include("utils.jl")
include("outerproduct_and_projection.jl")
# include("traits.jl")

include("abstract_block.jl")

# concrete blocks
include("routines.jl")
include("primitive/primitive.jl")
include("composite/composite.jl")
include("channel/channel.jl")


include("algebra.jl")
include("blocktools.jl")
include("measure_ops.jl")
include("layout.jl")
include("treeutils/treeutils.jl")

include("autodiff/autodiff.jl")
export AD, Optimise
using .Optimise: canonicalize

include("deprecations.jl")

include("backends.jl")

end # YaoBlocks
