using Test

using Yao
using Yao.Blocks: MathBlock, isunitary

"""
    pshift(n::Int) -> Function

return a peridoc shift function.
"""
pshift(n::Int) = (b::Int, nbit::Int) -> mod(b+n, 1<<nbit)
pshift(n::Float64) = (b::Float64, nbit::Int) -> mod(b+n, 1)

@testset "math" begin
    nbit = 5

    # bint
    ab = MathBlock{:Add3, nbit}(pshift(3))
    mb = MathBlock{:Minus3, nbit}(pshift(-3))
    @test apply!(zero_state(nbit), ab) == product_state(nbit, 3)
    @test apply!(zero_state(nbit), mb) == product_state(nbit, 1<<nbit-3)
    @test isunitary(ab)

    # bint_r
    ab = MathBlock{:Add3, nbit, :bint_r}(pshift(3))
    @test apply!(zero_state(nbit), ab) == product_state(nbit, 0b11000)
    @test isunitary(ab)

    # bfloat
    af = MathBlock{:AddFloat, nbit, :bfloat}(pshift(0.5))
    @test isunitary(af)
    @test apply!(zero_state(nbit), af) == product_state(nbit, 1)

    # bfloat_r
    af = MathBlock{:AddFloat, nbit, :bfloat_r}(pshift(0.5))
    @test isunitary(af)
    @test apply!(zero_state(nbit), af) == product_state(nbit, 0b10000)
end
