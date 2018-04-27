include("Core.jl")
include("Compose.jl")
include("Gates.jl")

struct GateBlock{N, GT} <: LeafBlock{N}
    gate::GT
end
