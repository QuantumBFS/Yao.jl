using Yao.EasyBuild
using Test, BitBasis

function toffli(b::BitStr)
    t = @inbounds b[1] ⊻ (b[3] & b[2])
    return @inbounds bit_literal(t, b[2], b[3])
end

"""
    pshift(n::Int) -> Function

return a peridoc shift function.
"""
pshift(n::Int) = function (b::BitStr{N}) where N mod(b+n, 1<<N) end

@testset "test toffli" begin
    g = Yao.EasyBuild.mathgate(3, toffli)
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
    ab = Yao.EasyBuild.mathgate(nbits, pshift(3))
    mb = Yao.EasyBuild.mathgate(nbits, pshift(-3))
    @test apply!(zero_state(nbits), ab) == product_state(nbits, 3)
    @test apply!(zero_state(nbits), mb) == product_state(nbits, 1<<nbits-3)
    @test applymatrix(ab) ≈ mat(ab)
    @test isunitary(ab)

    ab = Yao.EasyBuild.mathgate(nbits, pshift(3))
    @test apply!(zero_state(nbits), ab) == product_state(nbits, 0b00011)
    @test isunitary(ab)
end
