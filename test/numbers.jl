using Test, YaoSym
using YaoSym: SymExpr

@testset "arithmetics" begin
    @sym θ in Real, α

    @test θ * α == SymExpr(*, θ, α)
    @test θ * α == α * θ
    @test 2 * θ
end

@sym x in Real, y in Real
2x

2 * x * y + 3x
ex = x * (2y + x)

x * x

ex = (x + y) / (x + y)

@which Base.show(stdout, ex)

[x, y, x, y] * 2

using Yao

phase(x)