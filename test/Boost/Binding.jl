using Compat.Test
using Yao
using Yao.Intrinsics
using Yao.Blocks
using Yao.Boost

# @testset "Single Control" begin
#     cb = SingleControlBlock{XGate, 2, ComplexF64}(X, 2,1)
#     @test mat(cb) == Const.Sparse.CNOT
# end

@testset "Repeated" begin
    for G in [:X, :Y, :Z]
        @eval begin
            rb = RepeatedBlock{2}($G, [1,2])
            @test mat(rb) ≈ kron(mat($G), mat($G))
        end
    end
end

@testset "Multiple Control" begin
    mcb = ControlBlock{3}((3, 2), X, 1)
    @test mat(mcb) ≈ mat(Toffoli)
end
