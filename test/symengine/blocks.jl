using YaoSym, YaoBlocks, YaoArrayRegister, SymEngine
using YaoSym: simplify_expi
using SymEngine
using Test

@testset "imag and conj" begin
    @vars a b c
    @test imag(Basic(2+im*a)) == a
    @test imag(Basic((2+im)*(im*a+1))) == 2*a + 1
    @test real(sin(a)) == sin(a)
    @test imag(sin(a)) == 0
end

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
    @test smat(G) == m
    @test_throws ArgumentError mat(Float64, G)
    m = subs.(m, Ref(θ=>Basic(π)/2), Ref(γ=>Basic(π)/6))
    @test Matrix(mat(Rz(π/2)*Rx(π/6)*Rz(π/2))) ≈ Matrix(m)

    A = randn(ComplexF64, 4,4)
    mb = matblock(Basic.(A))
    @test Matrix(mb) ≈ A

    @test pswap(4,2,1,θ) == pswap(2,1,θ)(4)
    @test pswap(4,2,1,θ) isa PSwap{4,Basic}
end

@testset "Sym Engine Conj" begin
    @vars a b
    @test cos(exp(a+im*b))' == cos(exp(a-im*b))
    @test cos(exp(a+im*b))' == cos(exp(a-im*b))
    @test smat(Rx(a)) == [cos(a/2)  -im*sin(a/2);
                -im*sin(a/2)     cos(a/2)]
    @test smat(Rx(a)') == [cos(a/2)  im*sin(a/2);
                im*sin(a/2)     cos(a/2)]
end

@testset "expect" begin
    @vars a b
    reg = ket"111" |> control(3,1,2=>Rx(a))
    op = put(3, 2=>Z)
    reg2 = ArrayReg(bit"111") |> control(3,1,2=>Rx(0.5))
    ex = expect(op, reg)
    ex = subs(ex, a=>0.5)
    @test ComplexF64(ex) ≈ expect(op, reg2)
end

@testset "grad" begin
    @vars a b
    reg = ArrayReg(Basic, bit"111") => control(3,1,2=>Rx(a))
    op = put(3, 2=>Z)
    reg2 = ArrayReg(bit"111") => control(3,1,2=>Rx(0.5))
    ex = expect'(op, reg)[2]
    ex = subs(ex[], a=>0.5)
    @test ComplexF64(ex) ≈ expect'(op, reg2)[2][]
end

@testset "grad" begin
    @vars a b
    reg = ArrayReg(Basic, bit"000") => put(3,2=>Rx(a))
    op = put(3, 2=>Z)
    reg2 = ArrayReg(bit"000") => put(3,2=>Rx(0.9))
    ex = expect(op, reg)
    ex = subs(ex[], a=>0.9)
    @test ComplexF64(ex) ≈ expect(op, reg2)
    ex = expect'(op, reg)[2]
    ex = subs(ex[], a=>0.9)
    @test ComplexF64(ex) ≈ expect'(op, reg2)[2][]
end
