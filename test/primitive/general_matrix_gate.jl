using Test, Random, LinearAlgebra, YaoArrayRegister, YaoBlockTree

mg = matblock(rand(4, 4))
mg2 = copy(mg)
@test mg2 == mg

mg2.mat[:, 2] .= 10
@test mg2 != mg
@test nqubits(mg) == 2
@test_throws DimensionMismatch matblock(randn(3,3))

reg = rand_state(2)
@test apply!(copy(reg), mg) |> statevec == mat(mg) * reg.state |> vec
