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
include("Sequence.jl")

include("Measure.jl")
