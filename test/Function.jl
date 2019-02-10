using Test, Random, LinearAlgebra, SparseArrays

using YaoBase, YaoBlockTree

@testset "functor" begin
    Test_InvOrder = FunctionBlock(invorder!)
    reg = rand_state(4)
    @test copy(reg) |> invorder! == apply!(copy(reg), Test_InvOrder)
end
