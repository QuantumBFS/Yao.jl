######### Tests #########
using Compat.Test
include("physics.jl")
include("basis.jl")
p = ones(8).*0.125
q = real(ghz(3))

@testset "physics" begin
    @test isapprox(prob_from_sample([1,2,1,1], 1<<3), [0, 0.75, 0.25, 0, 0,0,0,0])
    @test sample_from_prob([1,3,1,1], [0.5, 0, 0, 0.5], 4) == [1,1,1,1]
end
