module Blocks

import Base: show

using Compat, MacroTools
using Compat.LinearAlgebra
using Compat.SparseArrays

using ..Basis
using ..Registers
using ..LuxurySparse

import ..Const
import ..Yao
import ..Intrinsics

import ..Yao: nqubits, ninput, noutput

# TODO: move GateType and related constant matrix to Utils/ (or Core/)
# TODO: Optimization for Primitive blocks

struct AnySize end
struct GreaterThan{N} end

import Base: ismatch
ismatch(::GreaterThan{N}, n::Int) where N = n > N
ismatch(::AnySize, n::Int) = true

include("Core.jl")
include("MatrixBlock.jl")

# others
include("Concentrator.jl")
# include("Sequence.jl")

include("Measure.jl")

include("show.jl")
end