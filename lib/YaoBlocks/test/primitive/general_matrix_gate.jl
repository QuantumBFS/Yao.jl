using Test, Random, LinearAlgebra, YaoArrayRegister, YaoBlocks, YaoBase

A = rand(ComplexF64, 4, 4)
mg = matblock(A)
mg2 = copy(mg)
@test mg2 == mg
@test mat(ComplexF64, mg) ≈ A
@test_logs (:warn,) mat(ComplexF32, mg)

mg2.mat[:, 2] .= 10
@test mg2 != mg
@test nqubits(mg) == 2
@test_throws ArgumentError matblock(randn(3, 3))
@test matblock(randn(3, 3); nlevel=3) isa GeneralMatrixBlock

reg = rand_state(2)
@test apply!(copy(reg), mg) |> statevec == mat(mg) * reg.state |> vec

@test matblock(X) == GeneralMatrixBlock(mat(X))

a = rand_unitary(2)
@test mat(matblock(a))' == mat(matblock(a)')

# fallback test #59, return a correct matrix type for matblock
a = rand_unitary(2) .|> ComplexF32
@test eltype(mat(matblock(a))) == ComplexF32
