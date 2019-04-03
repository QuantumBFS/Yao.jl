using Test, YaoBlocks

@testset "pauli strings" begin
    g = PauliString(X, Y, Z)
    g = PauliString([X, Y, Z])

    @test mat(g) ≈ mat(kron(3, X, Y, Z))
    @test chsubblocks(g, [X, X, X]) == PauliString(X, X, X)

    g[3] = I2
    @test occupied_locs(g) == [1, 2]

    ishermitian(g) == ishermitian(mat(g))
    isreflexive(g) == isreflexive(mat(g))
    isunitary(g) == isunitary(mat(g))
    length(g) == 3
end
