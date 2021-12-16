using Test, Yao.EasyBuild, YaoBlocks
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

    fs_ = to_basictypes(fs)
    @test mat(fs) ≈ Matrix(fs_)

    c  = chain(put(3,(3,1)=>fs), chain(put(3,(1,2)=>fs), put(3, (1,3)=>fs), put(3, (3,2)=>fs)))
    c_ = simplify(replace_block(fs=>fs_, c), rules=[to_basictypes])
    c  = chain(put(3,(3,1)=>fs_), chain(put(3,(1,2)=>fs_), put(3, (1,3)=>fs_), put(3, (3,2)=>fs_)))

    @test Matrix(c) ≈ Matrix(simplify(c_, rules=[to_basictypes]))
end
