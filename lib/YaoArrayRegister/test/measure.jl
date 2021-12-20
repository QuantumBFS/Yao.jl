using Test, YaoArrayRegister, YaoBase

@testset "select" begin
    reg = product_state(4, 6; nbatch=2)
    # println(focus!(reg, [1,3]))
    r1 = relax!(; to_nactive=2)(select!(focus!(copy(reg), [2, 3]), 0b11))
    r2 = relax!(; to_nactive=2)(select(focus!(copy(reg), [2, 3]), 0b11))
    r3 = relax!(; to_nactive=2)(select!(0b11)(focus!(2, 3)(copy(reg))))

    @test r1' * r1 ≈ ones(2)
    @test r1 ≈ r2
    @test r3 ≈ r2
end

@testset "measure and resetto/remove" begin
    reg = rand_state(4)
    res = measure!(YaoBase.ResetTo(0), reg, (4,))
    @test isnormalized(reg)
    result = measure(reg; nshots=10)
    @test all(result .< 8)
    @test ndims(res) == 0

    reg = focus!(1, 4, 3)(rand_state(6))
    reg0 = copy(reg)
    res = measure!(YaoBase.RemoveMeasured(), reg)
    @test nqubits(reg) == 3
    select(reg0, res)
    @test normalize!(select(reg0, res)) ≈ reg
    @test ndims(res) == 0

    r = rand_state(10)
    r1 = focus!(1, 4, 3)(copy(r))
    res = measure!(YaoBase.RemoveMeasured(), r, (1, 4, 3))
    r2 = select(r1, res)
    r2 = relax!(r2, (); to_nactive=nqubits(r2))
    @test normalize!(r2) ≈ r
    @test ndims(res) == 0

    reg = focus!((1:5)...)(rand_state(6; nbatch=5))
    res = measure!(YaoBase.ResetTo(0), reg, 1)
    @test nactive(reg) == 5
    @test ndims(res) == 1
end

@testset "fix measure kwargs error" begin
    r = rand_state(10)
    @test length(measure(r; nshots=10)) == 10
    @test_throws MethodError measure!(r; nshots=10)
    @test_throws MethodError measure!(YaoBase.RemoveMeasured(), r; nshots=10)
end

@testset "fix measure output type error" begin
    res = measure(rand_state(1; nbatch=10))
    @test res isa Matrix{BitStr64{1}}
end

@testset "fix measure kwargs error" begin
    r = rand_state(10)
    @test length(measure(r; nshots=10)) == 10
    @test_throws MethodError measure!(r; nshots=10)
    @test_throws MethodError measure!(YaoBase.RemoveMeasured(), r; nshots=10)
end
