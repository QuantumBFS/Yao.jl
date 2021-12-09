using Test, Yao.EasyBuild
using YaoBlocks.Optimise: replace_block, to_basictypes, simplify
using YaoBlocks: parse_ex

@testset "gates" begin
    @test isunitary(FSimGate(0.5, 0.6))
    fs = FSimGate(π/2, π/6)
    @test eval(parse_ex(dump_gate(fs), 1)) == fs
    cphase(nbits, i::Int, j::Int, θ::T) where T = control(nbits, i, j=>shift(θ))
    ic = ISWAP*cphase(2, 2, 1, π/6)
    @test mat(fs) ≈ mat(ic)'
    ISWAP_ = SWAP*rot(kron(Z,Z), π/2)
    @test Matrix(ISWAP) ≈ Matrix(ISWAP_)*exp(im*π/4)
end
