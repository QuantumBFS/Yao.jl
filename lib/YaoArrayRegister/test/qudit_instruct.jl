using YaoArrayRegister
using Test, LinearAlgebra
using YaoArrayRegister: accum_instruct!
using SparseArrays: sprand

@testset "operators" begin
    state = rand_state(6) |> statevec
    # general matrix
    for m in [YaoArrayRegister.IMatrix{1<<12,ComplexF64}(), randn(ComplexF64, 4, 4), YaoArrayRegister.pmrand(ComplexF64, 4), Diagonal(randn(ComplexF64, 4)), sprand(ComplexF64, 4, 4, 0.5)]
        @info "qudit gate, matrix type: ", typeof(m)
        expected = instruct!(Val(2), state, m, (3,4))
        @test expected ≈ instruct!(Val(4), state, m, (2,))
    end
end