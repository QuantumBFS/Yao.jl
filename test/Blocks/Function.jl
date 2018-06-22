using Compat
using Compat.Test

using Yao
using Yao.Blocks

@testset "functor" begin
    Test_InvOrder = FunctionBlock(invorder!)
    reg = rand_state(4)
    @test copy(reg) |> invorder! == apply!(copy(reg), Test_InvOrder)
end
