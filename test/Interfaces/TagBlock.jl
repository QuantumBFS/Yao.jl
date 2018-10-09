using Test, Random, LinearAlgebra

using Yao
using Yao.Blocks

"""
    loss_expect(circuit::AbstractBlock, op::AbstractBlock) -> Function

Return function "loss!(ψ, θ) -> Vector"
"""
function loss_expect!(circuit::AbstractBlock, op::AbstractBlock)
    N = nqubits(circuit)
    function loss!(ψ::AbstractRegister, θ::Vector)
        params = parameters(circuit)
        dispatch!(circuit, θ)
        ψ |> circuit
        dispatch!!(circuit, params)
        expect(op, ψ)
    end
end

"""
    loss_Z1!(circuit::AbstractBlock; ibit::Int=1) -> Function

Return the loss function f = <Zi> (means measuring the ibit-th bit in computation basis).
"""
loss_Z1!(circuit::AbstractBlock; ibit::Int=1) = loss_expect!(circuit, put(nqubits(circuit), ibit=>Z))

@testset "back propagate" begin
    c = put(4, 3=>Rx(0.5)) |> autodiff(:BP)
    cad = c'
    @test mat(cad) == mat(c)'

    circuit = chain(4, repeat(4, H, 1:4), put(4, 3=>Rz(0.5)) |> autodiff(:BP), control(2, 1=>X), put(4, 4=>Ry(0.2)) |> autodiff(:BP))
    op = put(4, 3=>Y)
    loss! = loss_expect!(circuit, op)
    θ = [0.1, 0.2]
    ψ0 = rand_state(4)
    ψ = copy(ψ0)
    loss = loss!(ψ, θ)

    # get gradient
    δ = ψ |> op
    backward!(δ, circuit)
    g1 = gradient(circuit)

    g2 = zero(θ)
    η = 0.01
    for i in 1:length(θ)
        θ1 = copy(θ)
        θ2 = copy(θ)
        θ1[i] -= 0.5η
        θ2[i] += 0.5η
        g2[i] = (loss!(copy(ψ0), θ2) - loss!(copy(ψ0), θ1))/η |> real
    end
    println(g1,g2)
    @test isapprox.(g1, g2, atol=1e-4) |> all
end

@testset "constructor" begin
    @test generator(put(4, 1=>Rx(0.1))) == put(4, 1=>X)
    @test generator(Rx(0.1)) == X
    circuit = chain(put(4, 1=>Rx(0.1)), control(4, 2, 1=>Ry(0.3)))
    c2 = circuit |> autodiff(:BP)
    @test c2[1] isa BPDiff
    @test !(c2[2] isa BPDiff)
end

@testset "numdiff & exactdiff" begin
    @test collect(sequence([X, Y, Z]), XGate) == sequence([X])

    c = chain(put(4, 1=>Rx(0.5))) |> autodiff(:QC)
    nd = numdiff(c[1].block) do
        expect(put(4, 1=>Z), zero_state(4) |> c) |> real # return loss please
    end

    ed = exactdiff(c[1].block) do
        expect(put(4, 1=>Z), zero_state(4) |> c) |> real
    end
    @test isapprox(nd, ed, atol=1e-4)

    reg = rand_state(4)
    c = chain(put(4, 1=>Rx(0.5)), control(4, 1, 2=>Ry(0.5)), kron(4, 2=>Rz(0.3), 3=>Rx(0.7))) |> autodiff(:QC)
    dbs = collect(c, QDiff)
    loss1z() = expect(kron(4, 1=>Z, 2=>X), copy(reg) |> c) |> real  # return loss please
    nd = numdiff.(loss1z, dbs)
    ed = exactdiff.(loss1z, dbs)
    gd = gradient(c)
    @test gradient(c, :QC) == gd
    @test gradient(c, :BP) == []
    @test isapprox(nd, ed, atol=1e-4)
    @test ed == gd
end
