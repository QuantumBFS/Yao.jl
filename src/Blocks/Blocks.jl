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
import ..Registers: focus!, relax!, datatype, measure!, measure_reset!, measure_remove!
import ..Intrinsics: ishermitian, isunitary, isreflexive, iscommute
import CacheServers: update!, iscached, clear!, pull, iscacheable
export clear! # TODO: rm this later
import Base: copy, hash, ==, eltype, show, similar, getindex, setindex!, iterate, length, parent, adjoint, lastindex, push!, append!, prepend!, insert!, +, -, *, /, pop!, popfirst!

# APIs for cache block's matrix
export update_cache

# module APIs
export usedbits, addrs, subblocks, block, chblock, chsubblocks, @const_gate, tokenof
export nqubits, nactive, mat, datatype, invorder
export iparameters, niparameters, setiparameters!, nparameters, parameters, parameter_type, iparameter_type
export apply!, dispatch!, dispatch!!, applymatrix
export ishermitian, isunitary, isreflexive, iscommute
export parent, adjoint
export blockfilter, blockfilter!, expect

include("Core.jl")
include("Sequential.jl")
include("MatrixBlock.jl")
# others
include("Measure.jl")
include("Function.jl")
include("IOSyntax.jl")

include("pauli_group.jl")
include("block_operations.jl")
include("linalg.jl")

end
