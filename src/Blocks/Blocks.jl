module Blocks

using Compat
using Compat.Random
using Compat.Iterators
using Compat.LinearAlgebra
using Compat.SparseArrays

using ..Intrinsics
using ..Registers
using ..LuxurySparse
using ..CacheServers

# import package APIs
import ..Yao
import ..Yao: DefaultType, nqubits, nactive
import ..Registers: focus!, relax!
import ..Intrinsics: ishermitian, isunitary, isreflexive
import ..CacheServers: update!, iscached, clear!, pull, iscacheable
import Base: copy, hash, ==, eltype, show, similar, getindex, setindex!, start, next, done, length


# APIs for cache block's matrix
export update_cache

# module APIs
export address, blocks, @const_gate
export nqubits, nactive, nparameters, mat, datatype, parameters
export apply!, dispatch!
export ishermitian, isunitary, isreflexive

include("Core.jl")
include("MatrixBlock.jl")
# others
include("Measure.jl")
include("IOSyntax.jl")

end
