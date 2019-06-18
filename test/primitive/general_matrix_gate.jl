using Test, Random, LinearAlgebra, YaoArrayRegister, YaoBlocks, YaoBase

A = rand(ComplexF64, 4, 4)
mg = matblock(A)
mg2 = copy(mg)
@test mg2 == mg
@test mat(ComplexF64, mg) ≈ A
@test_logs (:warn, "converting Complex{Float64} to eltype Complex{Float32}, consider create another matblock with eltype Complex{Float32}") mat(ComplexF32, mg)

mg2.mat[:, 2] .= 10
@test mg2 != mg
@test nqubits(mg) == 2
@test_throws DimensionMismatch matblock(randn(3,3))

reg = rand_state(2)
@test apply!(copy(reg), mg) |> statevec == mat(mg) * reg.state |> vec

@test matblock(X) == GeneralMatrixBlock(mat(X))

a = rand_unitary(2)
@test mat(matblock(a))' == mat(matblock(a)')
