using Test, YaoBlocks, YaoArrayRegister

reg = rand_state(10)
block = kron(4, 2=>X)
c = concentrate(10, block, [1, 3, 9, 2])
@test nqubits(c) == 10
@test nactive(c) == 4
@test isunitary(c) == true
@test isreflexive(c) == true
@test ishermitian(c) == true
blk = kron(4, 2=>Rx(0.3))
@test chsubblocks(c, [blk]) |> subblocks |> first == blk

@test apply!(copy(reg), c) == apply!(copy(reg), kron(10, 3=>X))

@testset "test repeat" begin
    c = concentrate(8, repeat(5, H), 1:5)
    r = rand_state(8)
    r1 = copy(r) |> c
    r2 = copy(r) |> repeat(8, H, 1:5)
    @test r1 ≈ r2
end
