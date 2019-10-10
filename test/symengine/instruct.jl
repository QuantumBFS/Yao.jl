using Test, YaoSym

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
    for GC in [Rx, Ry, Rz, shift, phase, θ->rot(SWAP,θ)]
        G = GC(θ)
        locs = nqubits(G) == 1 ? 2 : (3,1)
        g1 = put(4, locs=>GC(θ))
        g2 = put(4, locs=>GC(π/2))
        regs = state(copy(reg1) |> g1)
        res = subs.(regs, θ, Basic(π)/2)
        @test  res ≈ state(copy(reg2) |> g2)
    end

    CRk(::Type{T}, i::Int, j::Int, k::Int) where T = control([i, ], j=>shift(2*T(π)/(1<<k)))
    CRot(::Type{T}, n::Int, i::Int) where T = chain(n, i==j ? put(i=>H) : CRk(T, j, i, j-i+1) for j = i:n)
    qft(::Type{T}, n::Int) where T = chain(n, CRot(T, n, i) for i = 1:n)
    res = ket"11" |> qft(Basic, 2)
    l1 = length(string(res.state.nzval[2]))
    res.state.nzval .= simplify_expi.(res.state.nzval)
    @test length(string(res.state.nzval[2])) < l1
    @test res ≈ ArrayReg(bit"11") |> qft(Float64, 2)
end
