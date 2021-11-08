import Zygote, ForwardDiff
using Random, Test
using YaoBlocks, YaoArrayRegister

@testset "rules" begin
    h = put(5, 3=>Z) + put(5, 2=>X)
    c = chain(put(5, 2=>chain(Rx(1.4), Rx(0.5))), cnot(5, 3, 1), put(5, 3=>Rx(-0.5)))
    r = rand_state(5)
    g0 = reinterpret(ComplexF64, ForwardDiff.gradient(x->real(expect(h, ArrayReg([Complex(x[2i-1],x[2i]) for i=1:length(x)÷2]))), reinterpret(Float64,r.state)))
    @test Zygote.gradient(x->real(expect(h, ArrayReg(x))), r.state)[1] ≈ g0
    @test Zygote.gradient(x->real(expect(h, ArrayReg{1}(reshape(statevec(x),:,1)))), r)[1].state ≈ g0
    @test Zygote.gradient(x->real(expect(h, ArrayReg(reshape(state(x),:,1)))), r)[1].state ≈ g0
    @test Zygote.gradient(x->real(expect(h, copy(x))), r)[1].state ≈ g0
    @test Zygote.gradient(x->real(expect(h, parent(x'))), r)[1].state ≈ g0

    g1 = reinterpret(ComplexF64, ForwardDiff.gradient(x->real(sum(abs2, [Complex(x[2i-1],x[2i]) for i=1:length(x)÷2])), reinterpret(Float64,r.state)))
    @test Zygote.gradient(x->real(sum(abs2, state(x'))), r)[1].state ≈ g1
    @test Zygote.gradient(x->real(sum(abs2, statevec(x'))), r)[1].state ≈ g1
    # zygote does not work if `sin` is not here,
    # because it gives an adjoint of different type as the output matrix type.
    # do not modify the data type please! Zygote
    @test Zygote.gradient(x->real(sum(sin, Matrix(x))), c)[1] ≈ ForwardDiff.gradient(x->real(sum(sin, Matrix(dispatch(c, x)))), parameters(c))
end

@testset "adwith zygote" begin
    c = chain(put(5, 2=>chain(Rx(0.4), Rx(0.5))), cnot(5, 3, 1), put(5, 3=>Rx(-0.5)))
    dispatch!(c, :random)

    function loss(reg::AbstractRegister, circuit::AbstractBlock{N}) where N
        reg = apply(copy(reg), circuit)
        st = state(reg)
        sum(real(st.*st))
    end

    reg0 = zero_state(5)
    params = rand!(parameters(c))
    paramsδ = Zygote.gradient(params->loss(reg0, dispatch(c, params)), params)[1]
    regδ = Zygote.gradient(reg->loss(reg, c), reg0)[1]
    fparamsδ = ForwardDiff.gradient(params->loss(ArrayReg(Matrix{Complex{eltype(params)}}(reg0.state)), dispatch(c, params)), params)
    fregδ = ForwardDiff.gradient(x->loss(ArrayReg([Complex(x[2i-1],x[2i]) for i=1:length(x)÷2]), dispatch(c, Vector{real(eltype(x))}(parameters(c)))), reinterpret(Float64,reg0.state))
    @test fregδ ≈ reinterpret(Float64, regδ.state)
    @test fparamsδ ≈ paramsδ
end

@testset "add block" begin
    H = sum([chain(5, put(k=>Z)) for k=1:5])
    c = chain(put(5, 2=>chain(Rx(0.4), Rx(0.5))), cnot(5, 3, 1), put(5, 3=>Rx(-0.5)))
    dispatch!(c, :random)
    function loss(reg::AbstractRegister, circuit::AbstractBlock{N}) where N
            reg = apply(copy(reg), circuit)
            st = state(reg)
            reg2 = apply(copy(reg), H)
            st2 = state(reg2)
            sum(real(st.*st2))
    end

    reg0 = zero_state(5)
    params = rand!(parameters(c))
    paramsδ = Zygote.gradient(params->loss(reg0, dispatch(c, params)), params)[1]
    fparamsδ = ForwardDiff.gradient(params->loss(ArrayReg(Matrix{Complex{eltype(params)}}(reg0.state)), dispatch(c, params)), params)
    @test fparamsδ ≈ paramsδ

    regδ = Zygote.gradient(reg->loss(reg, c), reg0)[1]
    fregδ = ForwardDiff.gradient(x->loss(ArrayReg([Complex(x[2i-1],x[2i]) for i=1:length(x)÷2]), dispatch(c, Vector{real(eltype(x))}(parameters(c)))), reinterpret(Float64,reg0.state))
    @test fregδ ≈ reinterpret(Float64, regδ.state)
end