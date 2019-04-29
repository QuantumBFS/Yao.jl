using Yao, QuAlgorithmZoo
using Yao.ConstGate
using LinearAlgebra, Test, Random

@testset "BP diff" begin
    reg = rand_state(4)
    block = put(4, 2=>rot(X, 0.3))
    df = BPDiff(block)
    @test df.grad == 0
    @test nqubits(df) == 4

    df2 = BPDiff(rot(CNOT, 0.3))
    @test df2.grad == 0
    @test nqubits(df2) == 2
end

@testset "Qi diff" begin
    reg = rand_state(4)
    df2 = QDiff(rot(CNOT, 0.3))
    @test df2.grad == 0
    @test nqubits(df2) == 2

    @test df2' isa QDiff
    @test mat(df2) == mat(df2')'
end

"""
    loss_expect!(circuit::AbstractBlock, op::AbstractBlock) -> Function

Return function "loss!(ψ, θ) -> Vector"
"""
function loss_expect!(circuit::AbstractBlock, op::AbstractBlock)
    N = nqubits(circuit)
    function loss!(ψ::AbstractRegister, θ::Vector)
        params = parameters(circuit)
        dispatch!(circuit, θ)
        ψ |> circuit
        popdispatch!(circuit, params)
        expect(op, ψ)
    end
end

"""
    loss_Z1!(circuit::AbstractBlock; ibit::Int=1) -> Function

Return the loss function f = <Zi> (means measuring the ibit-th bit in computation basis).
"""
loss_Z1!(circuit::AbstractBlock; ibit::Int=1) = loss_expect!(circuit, put(nqubits(circuit), ibit=>Z))

cnot_entangler(n::Int, pairs) = chain(n, control(n, [ctrl], target=>X) for (ctrl, target) in pairs)

function rotor(nbit::Int, ibit::Int, noleading::Bool=false, notrailing::Bool=false)
    rt = chain(nbit, [put(nbit, ibit=>Rz(0.0)), put(nbit, ibit=>Rx(0.0)), put(nbit, ibit=>Rz(0.0))])
    noleading && popfirst!(rt)
    notrailing && pop!(rt)
    rt
end

rset(nbit::Int, noleading::Bool=false, notrailing::Bool=false) = chain(nbit, [rotor(nbit, j, noleading, notrailing) for j=1:nbit])

function ibm_diff_circuit(nbit, nlayer, pairs)
    circuit = chain(nbit)

    ent = cnot_entangler(nbit, pairs)
    for i = 1:(nlayer + 1)
        i!=1 && push!(circuit, ent)
        push!(circuit, rset(nbit, i==1, i==nlayer+1))
    end
    circuit
end

@testset "BP diff" begin
    c = put(4, 3=>Rx(0.5)) |> autodiff(:BP)
    cad = c'
    @test mat(cad) == mat(c)'

    circuit = chain(4, repeat(4, H, 1:4), put(4, 3=>Rz(0.5)) |> autodiff(:BP), control(4, 2, 1=>shift(0.4)) |> autodiff(:BP), control(2, 1=>X), put(4, 4=>Ry(0.2)) |> autodiff(:BP))
    op = put(4, 3=>Y)
    θ = [0.1, 0.2, 0.3]
    dispatch!(circuit, θ)
    loss! = loss_expect!(circuit, op)
    ψ0 = rand_state(4)
    ψ = copy(ψ0) |> circuit

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
    g3 = opdiff.(() -> copy(ψ0) |> circuit, collect_blocks(BPDiff, circuit), Ref(op))
    @test isapprox.(g1, g2, atol=1e-5) |> all
    @test isapprox.(g2, g3, atol=1e-5) |> all
end

@testset "constructor" begin
    @test generator(put(4, 1=>Rx(0.1))) == put(4, 1=>X)
    @test generator(Rx(0.1)) == X
    circuit = chain(put(4, 1=>Rx(0.1)), control(4, 2, 1=>Ry(0.3)))
    c2 = circuit |> autodiff(:BP)
    @test c2[1] isa BPDiff
    @test !(c2[2] isa BPDiff)
end

@testset "numdiff & opdiff" begin
    @test collect_blocks(XGate, chain([X, Y, Z])) == [X]

    c = chain(put(4, 1=>Rx(0.5))) |> autodiff(:QC)
    nd = numdiff(c[1].content) do
        expect(put(4, 1=>Z), zero_state(4) |> c) |> real # return loss please
    end

    ed = opdiff(c[1].content, put(4, 1=>Z)) do
        zero_state(4) |> c  # a function get output
    end
    @test isapprox(nd, ed, atol=1e-4)

    reg = rand_state(4)
    c = chain(put(4, 1=>Rx(0.5)), control(4, 1, 2=>Ry(0.5)), control(4, 1, 2=>shift(0.3)),  kron(4, 2=>Rz(0.3), 3=>Rx(0.7))) |> autodiff(:QC)
    dbs = collect_blocks(QDiff, c)
    loss1z() = expect(kron(4, 1=>Z, 2=>X), copy(reg) |> c) |> real  # return loss please
    nd = numdiff.(loss1z, dbs)
    ed = opdiff.(()->copy(reg) |> c, dbs, Ref(kron(4, 1=>Z, 2=>X)))
    gd = gradient(c)
    @test gradient(c, :QC) == gd
    @test gradient(c, :BP) == []
    @test isapprox(nd, ed, atol=1e-4)
    @test ed == gd
end

@testset "stat" begin
    nbit = 3
    f(x::Number, y::Number) = Float64(abs(x-y) < 1.5)
    x = 0:1<<nbit-1
    h = f.(x', x)
    V = StatFunctional(h)
    VF = StatFunctional{2}(f)
    prs = [1=>2, 2=>3, 3=>1]
    c = ibm_diff_circuit(nbit, 2, prs) |> autodiff(:QC)
    dispatch!(c, :random)
    dbs = collect_blocks(AbstractDiff,c)

    p0 = zero_state(nbit) |> c |> probs
    sample0 = measure(zero_state(nbit) |> c; nshots=5000)
    loss0 = expect(V, p0 |> as_weights)
    gradsn = numdiff.(()->expect(V, zero_state(nbit) |> c |> probs |> as_weights), dbs)
    gradse = statdiff.(()->zero_state(nbit) |> c |> probs |> as_weights, dbs, Ref(V), initial=p0 |> as_weights)
    gradsf = statdiff.(()->measure(zero_state(nbit) |> c; nshots=5000), dbs, Ref(VF), initial=sample0)
    @test all(isapprox.(gradse, gradsn, atol=1e-4))
    @test norm(gradsf-gradse)/norm(gradsf) <= 0.2

    # 1D
    h = randn(1<<nbit)
    V = StatFunctional(h)
    c = ibm_diff_circuit(nbit, 2, prs) |> autodiff(:QC)
    dispatch!(c, :random)
    dbs = collect_blocks(AbstractDiff, c)

    p0 = zero_state(nbit) |> c |> probs |> as_weights
    loss0 = expect(V, p0 |> as_weights)
    gradsn = numdiff.(()->expect(V, zero_state(nbit) |> c |> probs |> as_weights), dbs)
    gradse = statdiff.(()->zero_state(nbit) |> c |> probs |> as_weights, dbs, Ref(V))
    @test all(isapprox.(gradse, gradsn, atol=1e-4))
end
