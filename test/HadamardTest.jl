using Yao
using Test
using LinearAlgebra
using QuAlgorithmZoo
using YaoBlocks.ConstGate

single_swap_test_circuit(ϕ::Real) = hadamard_test_circuit(SWAP, ϕ)
single_swap_test(reg::AbstractRegister, ϕ::Real) = hadamard_test(SWAP, reg, ϕ)

@testset "state overlap" begin
    reg1 = rand_state(3) |> focus!(1,2)
    rho1 = reg1 |> ρ
    reg2 = rand_state(3) |> focus!(1,2)
    rho2 = reg2 |> ρ
    reg3 = rand_state(3) |> focus!(1,2)
    rho3 = reg3 |> ρ
    desired = tr(mat(rho1)*mat(rho2))
    c = swap_test_circuit(2, 2, 0)
    res = expect(put(5, 1=>Z), join(join(reg2, reg1), zero_state(1)) |> c) |> tr
    @test desired ≈ res
    desired = tr(mat(rho1)*mat(rho2)*mat(rho3)) |> real
    c = swap_test_circuit(2, 3, 0)
    res = expect(put(7, 1=>Z), reduce(⊗, [reg3, reg2, reg1, zero_state(1)]) |> c) |> tr |> real
    @test desired ≈ res
    desired = tr(mat(rho1)*mat(rho2)*mat(rho3)) |> imag
    c = swap_test_circuit(2, 3, -π/2)
    res = expect(put(7, 1=>Z), reduce(⊗, [reg3, reg2, reg1, zero_state(1)]) |> c) |> tr |> real
    @test desired ≈ res
end

@testset "hadamard test" begin
    nbit = 4
    U = put(nbit, 2=>Rx(0.2))
    reg = rand_state(nbit)

    @test hadamard_test(U, reg, 0.0) ≈ real(expect(U, reg))
    @test hadamard_test(U, reg, -π/2) ≈ imag(expect(U, reg))

    reg = zero_state(2) |> singlet_block()
    @test single_swap_test(reg, 0) ≈ -1

    reg = zero_state(2)
    @test single_swap_test(reg, 0) ≈ 1
    reg = product_state(2, 0b11)
    @test single_swap_test(reg, 0) ≈ 1
end
