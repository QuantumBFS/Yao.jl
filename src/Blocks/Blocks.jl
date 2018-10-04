module Blocks

using Random, LinearAlgebra, SparseArrays
using MacroTools: @forward
using LinearMaps
using Expokit: expmv
using DataStructures, CacheServers

using ..Intrinsics
using ..Registers
using LuxurySparse

# import package APIs
import ..Yao
import ..Yao: DefaultType, nqubits, nactive, invorder
import ..Registers: focus!, relax!
import ..Intrinsics: ishermitian, isunitary, isreflexive
import CacheServers: update!, iscached, clear!, pull, iscacheable
export clear! # TODO: rm this later
import Base: copy, hash, ==, eltype, show, similar, getindex, setindex!, iterate, length, parent, adjoint, lastindex

# APIs for cache block's matrix
export update_cache

# module APIs
export usedbits, addrs, blocks, @const_gate
export nqubits, nactive, nparameters, mat, datatype, parameters, parameter_type, invorder, hasparameter, isprimitive
export apply!, dispatch!, applymatrix
export ishermitian, isunitary, isreflexive
export parent, adjoint
export blockfilter, blockfilter!, expect

include("Core.jl")
include("Sequential.jl")
include("MatrixBlock.jl")
# others
include("Measure.jl")
include("Function.jl")
include("IOSyntax.jl")
include("blockoperations.jl")

end
