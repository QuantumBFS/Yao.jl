module YaoBlockTree

using Random, LinearAlgebra, SparseArrays
using MacroTools: @forward
using LinearMaps, DataStructures, CacheServers, LuxurySparse
using Expokit: expmv

using YaoBase, YaoDenseRegister, YaoBase.Basis, YaoBase.Math
using YaoDenseRegister: matvec
using YaoBase.Math: linop2dense
using TupleTools

import YaoDenseRegister: datatype
# APIs for cache block's matrix
export update_cache

# module APIs
export usedbits, addrs, subblocks, block, chblock, chsubblocks, @const_gate, tokenof
export nqubits, nactive, mat, datatype
export iparameters, niparameters, setiparameters!, nparameters, parameters, parameter_type, iparameter_type
export apply!, dispatch!, dispatch!!, applymatrix
export parent, adjoint
export blockfilter, blockfilter!, expect

include("general_matrix.jl")

include("abstract_block.jl")
include("Sequential.jl")
include("MatrixBlock.jl")

include("Measure.jl")
include("Function.jl")
include("IOSyntax.jl")

include("pauli_group.jl")
include("block_operations.jl")
include("linalg.jl")

include("interfaces.jl")
include("primitive_interface.jl")
include("cache_interface.jl")
include("sequence_interface.jl")

using LinearAlgebra: Adjoint
Base.:(|>)(reg::AbstractRegister, circuit::Union{AbstractBlock, Adjoint{<:Any, <:AbstractBlock}}) = apply!(reg, circuit)


end # module
