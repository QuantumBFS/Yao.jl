module Blocks

using Compat
using Compat.Random
using Compat.Iterators
using Compat.LinearAlgebra
using Compat.SparseArrays
using Lazy: @forward
using DataStructures
using CacheServers
import IterTools

using ..Intrinsics
using ..Registers
using ..LuxurySparse

# import package APIs
import ..Yao
import ..Yao: DefaultType, nqubits, nactive, invorder
import ..Registers: focus!, relax!
import ..Intrinsics: ishermitian, isunitary, isreflexive
import CacheServers: update!, iscached, clear!, pull, iscacheable
import Base: copy, hash, ==, eltype, show, similar, getindex, setindex!, start, next, done, length, parent
import Compat: adjoint

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
