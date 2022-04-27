using Yao.EasyBuild, Yao
using Test
using LinearAlgebra
using YaoBlocks.ConstGate

single_swap_test_circuit(ϕ::Real) = hadamard_test_circuit(SWAP, ϕ)
single_swap_test(reg, ϕ::Real) = hadamard_test(SWAP, reg, ϕ)

@testset "state overlap" begin
    reg1 = rand_state(3) |> focus!(1,2)
    rho1 = reg1 |> density_matrix
    reg2 = rand_state(3) |> focus!(1,2)
    rho2 = reg2 |> density_matrix
    reg3 = rand_state(3) |> focus!(1,2)
    rho3 = reg3 |> density_matrix
    desired = tr(Matrix(rho1)*Matrix(rho2))
    c = swap_test_circuit(2, 2, 0)
    res = expect(put(5, 1=>Z), join(join(reg2, reg1), zero_state(1)) |> c) |> tr
    @test desired ≈ res
    desired = tr(Matrix(rho1)*Matrix(rho2)*Matrix(rho3)) |> real
    c = swap_test_circuit(2, 3, 0)
    res = expect(put(7, 1=>Z), reduce(join, [reg3, reg2, reg1, zero_state(1)]) |> c) |> tr |> real
    @test desired ≈ res
    desired = tr(Matrix(rho1)*Matrix(rho2)*Matrix(rho3)) |> imag
    c = swap_test_circuit(2, 3, -π/2)
    res = expect(put(7, 1=>Z), reduce(join, [reg3, reg2, reg1, zero_state(1)]) |> c) |> tr |> real
    @test desired ≈ res
end

@testset "hadamard test" begin
    nbit = 4
    U = put(nbit, 2=>Rx(0.2))
    reg = rand_state(nbit)

    @test hadamard_test(U, reg, 0.0) ≈ real(expect(U, reg))
    @test hadamard_test(U, reg, -π/2) ≈ imag(expect(U, reg))

    reg = zero_state(2) |> EasyBuild.singlet_block()
    @test single_swap_test(reg, 0) ≈ -1

    reg = zero_state(2)
    @test single_swap_test(reg, 0) ≈ 1
    reg = product_state(2, 0b11)
    @test single_swap_test(reg, 0) ≈ 1
end