using YaoArrayRegister
using Test, LinearAlgebra
using SparseArrays: sprand

@testset "utils" begin
    @test YaoArrayRegister.map_index(Val(3), 5, (1,3)) == 5
    @test YaoArrayRegister.map_index(Val(3), 5, (3,1)) == 7
end

@testset "operators" begin
    state = rand_state(6) |> statevec
    # general matrix
    for m in [YaoArrayRegister.IMatrix{ComplexF64}(4), randn(ComplexF64, 4, 4), YaoArrayRegister.pmrand(ComplexF64, 4), Diagonal(randn(ComplexF64, 4)), sprand(ComplexF64, 4, 4, 0.5)]
        @info "qudit gate, matrix type: ", typeof(m)
        expected = instruct!(Val(2), state, m, (3,4))
        @test expected ≈ instruct!(Val(4), state, m, (2,))
    end
end

@testset "corner cases" begin
    state = rand_state(2) |> statevec
    # matrix size same as register size
    m = randn(ComplexF64, 4, 4)
    expected = instruct!(Val(2), state, m, (1,2))
    @test expected ≈ instruct!(Val(4), state, m, (1,))

    # an case that breaks during test
    state = randn(ComplexF64, 3)
    m = sparse([1, 2], [2,1], [1.0+0im, 1.0], 3, 3)
    expected = m * state
    @test expected ≈ instruct!(Val(3), state, m, (1,))
end
