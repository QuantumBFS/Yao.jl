using Compat
using Compat.Test

using Yao
using Yao.Blocks
import Yao.Blocks: Functor

@testset "functor" begin
    InvOrder = Functor(invorder!)
    reg = rand_state(4)
    @test copy(reg) |> invorder! == apply!(copy(reg), InvOrder)
end
