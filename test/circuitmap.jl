using YaoToEinsum
using Test, OMEinsum
using Yao
using Yao.EasyBuild: qft_circuit, variational_circuit, rand_google53
using SymEngine

@testset "YaoToEinsum.jl" begin
    n = 5
    a = rand_unitary(4)[:, 1:2]
    mb = matblock(OuterProduct(conj.(a), a))
    for c in [put(n, 2=>Y), put(n, 2=>ConstGate.P0), put(n, (2, 1)=>mb), put(n, 2=>ConstGate.P1), put(n, (5,3)=>SWAP), put(n, (4,2)=>ConstGate.CNOT), put(n, (2,3,1)=>kron(ConstGate.CNOT, X)),
            put(n, 2=>Z), control(n, -3, 2=>X), control(n, 3, 2=>X), control(n, (2, -1), 3=>Y), control(n, (4,1,-2), 5=>Z)]
        @show c
        C = chain([put(n, i=>Rx(rand()*2π)) for i=1:n]..., c)
        code, xs = yao2einsum(C; optimizer=nothing)
        optcode = optimize_code(code, uniformsize(code, 2), GreedyMethod())
        @test reshape(optcode(xs...; size_info=uniformsize(code, 2)), 1<<n, 1<<n) ≈ mat(C)
    end
end

@testset "Yao Extensions" begin
    n = 5
    for c in [qft_circuit(n), variational_circuit(n, 2), rand_google53(5; nbits=n)]
        optcode, xs = yao2einsum(c)
        @test reshape(optcode(xs...; size_info=uniformsize(optcode, 2)), 1<<n, 1<<n) ≈ mat(c)
    end
end

@testset "boundary conditions" begin
    n = 5
    c = qft_circuit(n)
    initial_state = Dict([i=>rand_state(1) for i=1:n])
    reg = join([initial_state[i] for i=n:-1:1]...)
    reg |> c
    inner = (2,3)
    focus!(reg, inner)
    for final_state in [Dict([i=>rand_state(1) for i in inner]), Dict([i=>1 for i in inner])]
        freg = join(YaoToEinsum.render_single_qubit_state(ComplexF64, final_state[3]), YaoToEinsum.render_single_qubit_state(ComplexF64, final_state[2]))
        net = yao2einsum(c; initial_state=initial_state, final_state=final_state, optimizer=TreeSA(nslices=3))
        println(net)
        @test vec(contract(net)) ≈ vec(transpose(statevec(freg)) * state(reg))
    end
end

@testset "symbolic" begin
    n = 5
    c = qft_circuit(n)
    initial_state = Dict([i=>zero_state(Basic, 1) for i=1:n])
    code, xs = yao2einsum(c; initial_state=initial_state)
    @test eltype(xs) == AbstractArray{Basic}
end

@testset "fix to basic type" begin
    c = chain(kron(X,X))
    @test (yao2einsum(c) |> first) isa OMEinsum.SlicedEinsum
end
