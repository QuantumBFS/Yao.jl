using Compat.Test
include("gates.jl")

@testset "basicgate" begin
    # check matrixes
    for (gate, MAT) in [
        (xgate, [0 1;1 0]),
        (ygate, [0 -im; im 0]),
        (zgate, [1 0; 0 -1]),
        #(hgate, (elem = 1 / sqrt(2); [elem elem; elem -elem])),
    ]
        println(gate(1, basis(1)))
        @test full(gate(1, basis(1))) == MAT
    end
end
