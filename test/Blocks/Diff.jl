using Yao
using Yao.Blocks
using LinearAlgebra, Test

@testset "Constrcut" begin
    reg = rand_state(4)
    block = put(4, 2=>rot(X, 0.3))
    df = Diff(block, copy(reg))
    @test df.grad == 0
    @test nqubits(df) == 4

    df2 = Diff(rot(CNOT, 0.3))
    @test df2.grad == 0
    @test nqubits(df2) == 2
end

@testset "diff adjoint" begin
    c = put(4, 3=>Rx(0.5)) |> autodiff
    cad = c'
    @test mat(cad) == mat(c)'

    circuit = chain(4, repeat(4, H, 1:4), put(4, 3=>Rz(0.5)) |> autodiff, control(2, 1=>X), put(4, 4=>Ry(0.2)) |> autodiff)
    op = put(4, 3=>Y)
    loss! = loss_expect!(circuit, op)
    θ = [0.1, 0.2]
    ψ0 = rand_state(4)
    ψ = copy(ψ0)
    loss = loss!(ψ, θ)

    # get gradient
    δ = ψ |> op
    g1 = gradient(circuit, δ)

    g2 = zero(θ)
    η = 0.01
    for i in 1:length(θ)
        θ1 = copy(θ)
        θ2 = copy(θ)
        θ1[i] -= 0.5η
        θ2[i] += 0.5η
        g2[i] = (loss!(copy(ψ0), θ2) - loss!(copy(ψ0), θ1))/η |> real
    end
    @test isapprox.(g1, g2, atol=1e-5) |> all
end

@testset "autodiff" begin
    @test generator(put(4, 1=>Rx(0.1))) == put(4, 1=>X)
    @test generator(Rx(0.1)) == X
    circuit = chain(put(4, 1=>Rx(0.1)), control(4, 2, 1=>Ry(0.3)))
    c2 = circuit |> autodiff
    @test c2[1] isa Diff
    @test !(c2[2] isa Diff)
end
