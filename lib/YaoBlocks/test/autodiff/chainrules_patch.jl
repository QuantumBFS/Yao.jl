import Zygote, ForwardDiff
using Random, Test
using YaoBlocks, YaoArrayRegister
using ChainRulesCore: Tangent

@testset "recursive_create_tangent" begin
    c = chain(put(5, 2 => chain(Rx(1.4), Rx(0.5))), cnot(5, 3, 1), put(5, 3 => Rx(-0.5)))
    tc = YaoBlocks.AD.recursive_create_tangent(c)
    @test tc isa Tangent
end

@testset "construtors" begin
    @test Zygote.gradient(x -> x.list[1].blocks[1].theta, sum([chain(1, Rz(0.3))]))[1] == (
        list = NamedTuple{
            (:blocks,),
            Tuple{Vector{NamedTuple{(:block, :theta),Tuple{Nothing,Float64}}}},
        }[(blocks = [(block = nothing, theta = 1.0)],)],
    )
    @test_broken Zygote.gradient(
        x -> getfield(getfield(x, :content), :theta),
        Daggered(Rx(0.5)),
    )[1] == (content = (block = nothing, theta = 1.0),)
end

@testset "rules" begin
    h = put(5, 3 => Z) + put(5, 2 => X)
    c = chain(put(5, 2 => chain(Rx(1.4), Rx(0.5))), cnot(5, 3, 1), put(5, 3 => Rx(-0.5)))
    r = rand_state(5)
    g0 = reinterpret(
        ComplexF64,
        ForwardDiff.gradient(
            x -> real(
                expect(h, ArrayReg([Complex(x[2i-1], x[2i]) for i = 1:length(x)÷2])),
            ),
            reinterpret(Float64, r.state),
        ),
    )
    @test Zygote.gradient(x -> real(expect(h, ArrayReg(x))), r.state)[1] ≈ g0
    @test Zygote.gradient(
        x -> real(expect(h, ArrayReg(reshape(statevec(x), :, 1)))),
        r,
    )[1].state ≈ g0
    @test Zygote.gradient(
        x -> real(expect(h, ArrayReg(reshape(state(x), :, 1)))),
        r,
    )[1].state ≈ g0
    @test Zygote.gradient(x -> real(expect(h, copy(x))), r)[1].state ≈ g0
    @test Zygote.gradient(x -> real(expect(h, parent(x'))), r)[1].state ≈ g0

    g1 = reinterpret(
        ComplexF64,
        ForwardDiff.gradient(
            x -> real(sum(abs2, [Complex(x[2i-1], x[2i]) for i = 1:length(x)÷2])),
            reinterpret(Float64, r.state),
        ),
    )
    @test Zygote.gradient(x -> real(sum(abs2, state(x'))), r)[1].state ≈ g1
    @test Zygote.gradient(x -> real(sum(abs2, statevec(x'))), r)[1].state ≈ g1
    # zygote does not work if `sin` is not here,
    # because it gives an adjoint of different type as the output matrix type.
    @test AD.extract_circuit_gradients!(
        Zygote.gradient(x -> real(sum(sin, Matrix(x))), c)[1].blocks,
        Float64[],
    ) ≈ ForwardDiff.gradient(x -> real(sum(sin, Matrix(dispatch(c, x)))), parameters(c))
end

@testset "adwith zygote" begin
    c = chain(put(5, 2 => chain(Rx(0.4), Rx(0.5))), cnot(5, 3, 1), put(5, 3 => Rx(-0.5)))
    dispatch!(c, :random)

    function loss(reg::AbstractRegister, circuit::AbstractBlock{N}) where {N}
        reg = apply(copy(reg), circuit)
        st = state(reg)
        sum(real(st .* st))
    end

    # apply
    reg0 = zero_state(5)
    params = rand!(parameters(c))
    paramsδ = Zygote.gradient(params -> loss(reg0, dispatch(c, params)), params)[1]
    regδ = Zygote.gradient(reg -> loss(reg, c), reg0)[1]
    fparamsδ = ForwardDiff.gradient(
        params -> loss(
            ArrayReg(Matrix{Complex{eltype(params)}}(reg0.state)),
            dispatch(c, params),
        ),
        params,
    )
    fregδ = ForwardDiff.gradient(
        x -> loss(
            ArrayReg([Complex(x[2i-1], x[2i]) for i = 1:length(x)÷2]),
            dispatch(c, Vector{real(eltype(x))}(parameters(c))),
        ),
        reinterpret(Float64, reg0.state),
    )
    @test fregδ ≈ reinterpret(Float64, regδ.state)
    @test fparamsδ ≈ paramsδ

    # expect and fidelity
    c = chain(
        put(5, 5 => Rx(1.5)),
        put(5, 1 => Rx(0.4)),
        put(5, 4 => Rx(0.2)),
        put(5, 2 => chain(Rx(0.4), Rx(0.5))),
        cnot(5, 3, 1),
        put(5, 3 => Rx(-0.5)),
    )
    h = chain(repeat(5, X, 1:5))
    reg = rand_state(5)
    function loss2(reg::AbstractRegister, circuit::AbstractBlock{N}) where {N}
        return 5 *
               real(expect(h, copy(reg) => circuit) + fidelity(reg, apply(reg, circuit)))
    end
    params = rand!(parameters(c))
    fδc = ForwardDiff.gradient(
        params -> loss2(
            ArrayReg(Matrix{Complex{eltype(params)}}(reg.state)),
            dispatch(c, params),
        ),
        params,
    )
    δr, δc = Zygote.gradient((reg, params) -> loss2(reg, dispatch(c, params)), reg, params)
    @test δc ≈ fδc

    fregδ = ForwardDiff.gradient(
        x -> loss2(
            ArrayReg([Complex(x[2i-1], x[2i]) for i = 1:length(x)÷2]),
            dispatch(c, Vector{real(eltype(x))}(params)),
        ),
        reinterpret(Float64, reg.state),
    )
    @test fregδ ≈ reinterpret(Float64, δr.state)

    # operator fidelity
    c = chain(
        put(5, 5 => Rx(1.5)),
        put(5, 1 => Rx(0.4)),
        put(5, 4 => Rx(0.2)),
        put(5, 2 => chain(Rx(0.4), Rx(0.5))),
        cnot(5, 3, 1),
        put(5, 3 => Rx(-0.5)),
    )
    h = chain(repeat(5, X, 1:5))
    function loss3(circuit::AbstractBlock{N}, h) where {N}
        return operator_fidelity(circuit, h)
    end
    params = rand!(parameters(c))
    fδc = ForwardDiff.gradient(params -> loss3(dispatch(c, params), h), params)
    δc, = Zygote.gradient(p -> loss3(dispatch(c, p), h), params)
    @test δc ≈ fδc

    # NOTE: operator back propagation in expect is not implemented!
    # to differentiate operators, we need to use the expensive `mat_back` function.
end

@testset "add block" begin
    H = sum([chain(5, put(k => Z)) for k = 1:5])
    c = chain(put(5, 2 => chain(Rx(0.4), Rx(0.5))), cnot(5, 3, 1), put(5, 3 => Rx(-0.5)))
    dispatch!(c, :random)
    function loss(reg::AbstractRegister, circuit::AbstractBlock{N}) where {N}
        reg = apply(copy(reg), circuit)
        st = state(reg)
        reg2 = apply(copy(reg), H)
        st2 = state(reg2)
        sum(real(st .* st2))
    end

    reg0 = zero_state(5)
    params = rand!(parameters(c))
    paramsδ = Zygote.gradient(params -> loss(reg0, dispatch(c, params)), params)[1]
    fparamsδ = ForwardDiff.gradient(
        params -> loss(
            ArrayReg(Matrix{Complex{eltype(params)}}(reg0.state)),
            dispatch(c, params),
        ),
        params,
    )
    @test fparamsδ ≈ paramsδ

    regδ = Zygote.gradient(reg -> loss(reg, c), reg0)[1]
    fregδ = ForwardDiff.gradient(
        x -> loss(
            ArrayReg([Complex(x[2i-1], x[2i]) for i = 1:length(x)÷2]),
            dispatch(c, Vector{real(eltype(x))}(parameters(c))),
        ),
        reinterpret(Float64, reg0.state),
    )
    @test fregδ ≈ reinterpret(Float64, regδ.state)
end
