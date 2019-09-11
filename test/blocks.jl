using YaoSym, Yao, SymEngine
using Test

@testset "mat" begin
    @vars θ γ η
    for G in [X, ConstGate.T, H]
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
    m = subs.(m, Ref(θ=>Basic(π)/2), Ref(γ=>Basic(π)/6))
    @test Matrix(mat(Rz(π/2)*Rx(π/6)*Rz(π/2))) ≈ Matrix(m)

    A = randn(ComplexF64, 4,4)
    mb = matblock(Basic.(A))
    @test Matrix(mb) ≈ A
end

@testset "apply" begin
    @vars θ γ η
    reg2 = rand_state(4)
    reg1 = ArrayReg(Basic.(state(reg2)))
    for G in [X, ConstGate.T, H]
        g = control(4, 3, 2=>G)
        @test copy(reg1) |> g ≈ copy(reg2) |> g
        # print reg2 errors
    end

    reg2 = ArrayReg(bit"0011")
    reg1 = ArrayReg(Basic.(state(reg2)))
    for GC in [Rx, shift, phase]
        G = GC(θ)
        g1 = put(4, 2=>GC(θ))
        g2 = put(4, 2=>GC(π/2))
        regs = state(copy(reg1) |> g1)
        res = subs.(regs, θ, Basic(π)/2)
        @test  res ≈ state(copy(reg2) |> g2)
    end

    CRk(::Type{T}, i::Int, j::Int, k::Int) where T = control([i, ], j=>shift(2*T(π)/(1<<k)))
    CRot(::Type{T}, n::Int, i::Int) where T = chain(n, i==j ? put(i=>H) : CRk(T, j, i, j-i+1) for j = i:n)
    qft(::Type{T}, n::Int) where T = chain(n, CRot(T, n, i) for i = 1:n)
    res = ket"11" |> qft(Basic, 2)
    @show res
    l1 = length(string(res.state.nzval[2]))
    res.state.nzval .= simplify_expi.(res.state.nzval)
    @show res
    @test length(string(res.state.nzval[2])) < l1
    @test res ≈ ArrayReg(bit"11") |> qft(Float64, 2)
end
