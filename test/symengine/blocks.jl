using YaoSym, YaoBlocks, YaoArrayRegister, SymEngine
using YaoSym: simplify_expi
using Test

@testset "mat" begin
    @vars θ γ η
    for G in [X, Y, Z, ConstGate.T, H]
        @test Matrix(mat(Basic, G)) ≈ Matrix(mat(G))
        @test Matrix(mat(Basic, control(4, 3, 2=>G))) ≈ Matrix(control(4, 3, 2=>G))
    end

    for GC in [Rx, shift, phase]
        G = GC(θ)
        m = mat(Basic, G)
        m = subs.(m, θ, 0.5)
        @test Matrix(mat(GC(0.5))) ≈ Matrix(m)
        @test subs.(Matrix(mat(Basic, put(4, 2=>G))), θ, 0.5) ≈ Matrix(put(4, 2=>GC(0.5)))
    end

    G = Rz(θ)*Rx(γ)*Rz(θ)
    m = mat(Basic, G)
    @test_throws ArgumentError mat(Float64, G)
    m = subs.(m, Ref(θ=>Basic(π)/2), Ref(γ=>Basic(π)/6))
    @test Matrix(mat(Rz(π/2)*Rx(π/6)*Rz(π/2))) ≈ Matrix(m)

    A = randn(ComplexF64, 4,4)
    mb = matblock(Basic.(A))
    @test Matrix(mb) ≈ A

    @test pswap(4,2,1,θ) == pswap(2,1,θ)(4)
    @test pswap(4,2,1,θ) isa PSwap{4,Basic}
end
