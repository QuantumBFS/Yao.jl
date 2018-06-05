using Compat
using Compat.Test

@testset "binding" begin
include("Binding.jl")
end

@testset "applys" begin
include("applys.jl")
end

@testset "gates" begin
include("Gates.jl")
end
