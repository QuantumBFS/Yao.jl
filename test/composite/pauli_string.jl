using Test, YaoBlocks, YaoArrayRegister

@test_throws ErrorException PauliString([X, Y, H])

g = PauliString(X, Y, Z)
@test collect(subblocks(g)) == [X, Y, Z]
@test g[1] == X
@test g[end] == Z

@test collect(g) == [X, Y, Z]
@test eltype(g) == ConstGate.PauliGate

r = rand_state(3)
@test apply!(copy(r), g) ≈ apply!(copy(r), kron(X, Y, Z))

g = PauliString([X, Y, Z])

@test mat(g) ≈ mat(kron(3, X, Y, Z))
@test chsubblocks(g, [X, X, X]) == PauliString(X, X, X)

g[3] = I2
@test occupied_locs(g) == [1, 2]

@test ishermitian(g) == ishermitian(mat(g))
@test isreflexive(g) == isreflexive(mat(g))
@test isunitary(g) == isunitary(mat(g))
@test length(g) == 3

@test cache_key(g) == [cache_key(g[1]), cache_key(g[2]), cache_key(g[3])]