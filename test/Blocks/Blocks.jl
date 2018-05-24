using Compat.Test

@testset "matrix block" include("MatrixBlock.jl")
@testset "concentrator" include("Concentrator.jl")
@testset "sequence" include("Sequence.jl")
@testset "measure" include("Measure.jl")
