using Compat.Test

@testset "core APIs" begin
    include("Core.jl")
end

@testset "matrix block" begin
include("MatrixBlock.jl")
end

@testset "concentrator" begin
include("Concentrator.jl")
end

@testset "sequence" begin
include("Sequence.jl")
end

@testset "measure" begin
include("Measure.jl")
end
