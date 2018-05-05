using Compat.Test

import QuCircuit: is_size_match, AnySize

@testset "test utils" begin

    @test is_size_match(1, 1) == true
    @test is_size_match(1, 2) == false
    @test is_size_match(AnySize, 2) == true

end

include("Concentrator.jl")
include("Sequence.jl")