using Yao
using BitBasis
using Test, LinearAlgebra
using QuAlgorithmZoo

"""
random phase estimation problem setup.
"""
function rand_phaseest_setup(N::Int)
    U = rand_unitary(1<<N)
    b = randn(ComplexF64, 1<<N); b=b/norm(b)
    phases, evec = eigen(U)
    ϕs = @. mod(angle(phases)/2/π, 1)
    return U, b, ϕs, evec
end

@testset "phaseest" begin
    # Generate a random matrix.
    N = 3
    V = rand_unitary(1<<N)

    # Initial Set-up.
    phases = rand(1<<N)
    ϕ = Int(0b111101)/(1<<6)
    phases[3] = ϕ
    signs = exp.(2π*im.*phases)
    U = V*Diagonal(signs)*V'
    b = V[:,3]

    # Define ArrayReg and U operator.
    M = 6
    reg1 = zero_state(M)
    reg2 = ArrayReg(b)
    UG = matblock(U)

    # circuit
    circuit = PEBlock(UG, M, N)

    # run
    reg = apply!(join(reg2, reg1), circuit)

    # measure
    res = breflect(measure(focus!(copy(reg), 1:M); nshots=10)[1]; nbits=M) / (1<<M)

    @test res ≈ ϕ
    @test apply!(reg, circuit |> adjoint) ≈ join(reg2, reg1)
end

@testset "phaseest, non-eigen" begin
    # Generate a random matrix.
    N = 3
    U, b, ϕs, evec = rand_phaseest_setup(N)

    # Define ArrayReg and U operator.
    M = 6
    reg1 = zero_state(M)
    reg2 = ArrayReg(b)
    UG = matblock(U);

    # run circuit
    reg= join(reg2, reg1)
    pe = PEBlock(UG, M, N)
    apply!(reg, pe)

    # measure
    bs, proj, amp_relative = projection_analysis(evec, focus!(reg, M+1:M+N))
    @test isapprox(ϕs, bfloat.(bs, nbits=M), atol=0.05)
end
