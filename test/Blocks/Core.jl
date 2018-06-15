using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao

@testset "dispatch" begin
g = chain(phase(0.1), phase(0.2), X, phase(0.3))

@test parameters(g) isa Array{Float64, 1}
@test nparameters(g) == 3

for (i, each) in enumerate(parameters(g))
    @test each ≈ i * 0.1
end

g = kron(5, 3=>g, X, phase(0.4))
@test parameters(g) isa Array{Float64, 1}
@test nparameters(g) == 4

for (i, each) in enumerate(parameters(g))
    @test each ≈ i * 0.1
end

g = rollrepeat(4, chain(phase(0.1), shift(0.2)))
@test nparameters(g) == 8
@test parameters(g) isa Array{Float64, 1}

for (i, each) in enumerate(parameters(g))
    if i % 2 == 0
        @test each ≈ 0.2
    else
        @test each ≈ 0.1
    end
end

end
