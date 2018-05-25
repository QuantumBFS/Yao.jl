using Compat.Test
using QuCircuit

import QuCircuit: Roller

@testset "tile one block" begin
    g = Roller{5}(X())
    @test state(g(register(bit"11111"))) == state(register(bit"00000"))
end

@testset "roll multiple blocks" begin

g = Roller{5, Complex128}((X(), Y(), Z(), X(), X()))
tg = kron(5, X(), Y(), Z(), X(), X())
@test state(g(register(bit"11111"))) == state(tg(register(bit"11111")))

end
