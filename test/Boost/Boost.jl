using Compat
using Compat.Test

@testset "control" begin
include("Control.jl")
end

@testset "repeated" begin
include("Repeated.jl")
end

@testset "applys" begin
include("applys.jl")
end

@testset "gates" begin
include("Gates.jl")
end
