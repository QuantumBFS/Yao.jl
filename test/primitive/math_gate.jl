using Test, YaoArrayRegister, YaoBlockTree, BitBasis

function toffli(b::BitStr)
    t = @inbounds b[1] ⊻ (b[3] & b[2])
    return @inbounds bit_literal(t, b[2], b[3])
end

"""
    pshift(n::Int) -> Function

return a peridoc shift function.
"""
pshift(n::Int) = (b::Int, nbit::Int) -> mod(b+n, 1<<nbit)
pshift(n::Float64) = (b::Float64, nbit::Int) -> mod(b+n, 1)

@testset "test toffli" begin
    g = mathgate(toffli; nbits=3)
    check_truth(b1, b2) = apply!(ArrayReg(b1), g) == ArrayReg(b2)
    @test check_truth(bit"000", bit"000")
    @test check_truth(bit"001", bit"001")
    @test check_truth(bit"010", bit"010")
    @test check_truth(bit"011", bit"011")
    @test check_truth(bit"100", bit"100")
    @test check_truth(bit"101", bit"101")
    @test check_truth(bit"110", bit"111")
    @test check_truth(bit"111", bit"110")
end

@testset "test pshift" begin
    # bint
    nbits = 5
    ab = mathgate(pshift(3); nbits=nbits)
    mb = mathgate(pshift(-3); nbits=nbits)
    @test apply!(zero_state(nbits), ab) == product_state(nbits, 3)
    @test apply!(zero_state(nbits), mb) == product_state(nbits, 1<<nbits-3)
    @test isunitary(ab)

    ab = mathgate(pshift(3); nbits=nbits, bview=bint_r)
    @test apply!(zero_state(nbits), ab) == product_state(nbits, 0b11000)
    @test isunitary(ab)

    af = mathgate(pshift(0.5); nbits=nbits, bview=bfloat)
    @test isunitary(af)
    @test apply!(zero_state(nbits), af) == product_state(nbits, 1)

    # bfloat_r
    af = mathgate(pshift(0.5); nbits=nbits, bview=bfloat_r)
    @test isunitary(af)
    @test apply!(zero_state(nbits), af) == ArrayReg(bit"10000")
end
