using Compat.Test

import QuCircuit: KronBlock
import QuCircuit: Cache, rand_state, state, focus!, X, Y, Z, gate, phase, cache
# Block Trait
import QuCircuit: nqubit, ninput, noutput, isunitary,
                iscacheable, cache_type, ispure, get_cache
# Required Methods
import QuCircuit: apply!, update!, cache!

⊗ = kron

@testset "contiguous" begin
    # default should organize this as
    # contiguous gates on address
    # -- [X] --
    # -- [Y] --
    # -- [Z] --
    g = kron(gate(X), gate(Y), gate(Z))

    @test nqubit(g) == 3
    @test ninput(g) == 3
    @test noutput(g) == 3
    @test isunitary(g) == true
    @test iscacheable(g) == true
    @test cache_type(g) == Cache
    @test ispure(g) == true
    @test get_cache(g) == Dict()

    # check matrix form
    mat = sparse(gate(X)) ⊗ sparse(gate(Y)) ⊗ sparse(gate(Z))
    @test sparse(g) == mat
    @test full(g) == full(mat)

    reg = rand_state(3)
    @test full(g) * state(reg) == state(apply!(reg, g))

    # do nothing
    @test update!(g) == g
end

@testset "mixin parameter" begin
    g = kron(phase(1.0), gate(X), phase(2.0))

    @test nqubit(g) == 3
    @test ninput(g) == 3
    @test noutput(g) == 3
    @test isunitary(g) == true
    @test iscacheable(g) == true
    @test cache_type(g) == Cache
    @test ispure(g) == true
    @test get_cache(g) == Dict()

    mat = sparse(phase(1.0)) ⊗ sparse(gate(X)) ⊗ sparse(phase(2.0))
    @test sparse(g) == mat
    @test full(g) == full(mat)

    # do nothing
    @test update!(g) == g

    # update parameter
    update!(g, (1, 5.0))
    @test g[1].theta == 5.0
    update!(g, (1, -1.0), (3, 0.0))
    @test g[1].theta == -1.0
    @test g[3].theta == 0.0
end

@testset "in-contiguous" begin

    g = kron(gate(X), (3, gate(Z)), gate(X))

    @test nqubit(g) == 4
    @test ninput(g) == 4
    @test noutput(g) == 4
    @test isunitary(g) == true
    @test iscacheable(g) == true
    @test cache_type(g) == Cache
    @test ispure(g) == true
    @test get_cache(g) == Dict()

    mat = sparse(gate(X)) ⊗ speye(2) ⊗ sparse(gate(Z)) ⊗ sparse(gate(X))
    @test sparse(g) == mat
    @test full(g) == full(mat)

end

@testset "contiguous iterator" begin
    space = linspace(-pi, pi, 5)
    g = kron(phase(theta) for theta in space)

    @test nqubit(g) == length(space)
    @test ninput(g) == length(space)
    @test noutput(g) == length(space)
    @test isunitary(g) == true
    @test iscacheable(g) == true
    @test cache_type(g) == Cache
    @test ispure(g) == true
    @test get_cache(g) == Dict()

    blocks = collect(values(g))
    mat = sparse(first(blocks))
    for i = 2:length(space)
        mat = kron(mat, sparse(blocks[i]))
    end

    @test sparse(g) == mat
    @test full(g) == full(mat)
end

@testset "in-contiguous iterator" begin
    range = 1:2:5
    space = linspace(-pi, pi, length(range))
    g = kron((k, phase(theta)) for (k, theta) in zip(range, space)) # address 1, 3, 5

    @test nqubit(g) == 5
    @test ninput(g) == 5
    @test noutput(g) == 5
    @test isunitary(g) == true
    @test iscacheable(g) == true
    @test cache_type(g) == Cache
    @test ispure(g) == true
    @test get_cache(g) == Dict()

    blocks = collect(values(g))
    mat = sparse(blocks[1]) ⊗ speye(2) ⊗ sparse(blocks[2]) ⊗ speye(2) ⊗ sparse(blocks[3])
    @test sparse(g) == mat
    @test full(g) == full(mat)
end

@testset "manual total qubits" begin

    g = kron(2, gate(X))
    @test nqubit(g) == 2
    mat = sparse(gate(X)) ⊗ speye(2)
    @test sparse(g) == mat

    g = kron(5, gate(X), gate(Y))

    @test nqubit(g) == 5
    @test ninput(g) == 5
    @test noutput(g) == 5
    @test isunitary(g) == true
    @test iscacheable(g) == true
    @test cache_type(g) == Cache
    @test ispure(g) == true
    @test get_cache(g) == Dict()

    mat = sparse(gate(X)) ⊗ sparse(gate(Y)) ⊗ speye(8)
    @test sparse(g) == mat
    @test full(g) == full(mat)

    # check in-contiguous address from beginning
    g = kron(5, (2, gate(X)), gate(Y))

    @test nqubit(g) == 5

    mat = speye(2) ⊗ sparse(gate(X)) ⊗ sparse(gate(Y)) ⊗ speye(4)
    @test sparse(g) == mat
    @test full(g) == full(mat)
end

@testset "inner cache" begin

    g = kron((k, cache(phase(0.2), k)) for k=2:2:6) # address 2, 4, 6

    @test nqubit(g) == 6
    @test ninput(g) == 6
    @test noutput(g) == 6
    @test isunitary(g) == true
    @test iscacheable(g) == true
    @test cache_type(g) == Cache
    @test ispure(g) == true

    cache!(g, 3) # cache (2, phase(0.2))
    @test length(g[2].cache) == 1
    @test length(g[4].cache) == 0
    @test length(g[6].cache) == 0

    empty!(g)
    @test length(g[2].cache) == 0
    @test length(g[4].cache) == 0
    @test length(g[6].cache) == 0

    cache!(g, 10) # cache all
    @test length(g[2].cache) == 1
    @test length(g[4].cache) == 1
    @test length(g[6].cache) == 1

    update!(g, (4, 0.6)) # update 4 phase(0.2) -> phase(0.6)
    cache!(g, 10) # only update cache for the gate on 4
    @test length(g[2].cache) == 1
    @test length(g[4].cache) == 2
    @test length(g[6].cache) == 1

    cache_data = get_cache(g)
    @test cache_data[2] === g[2].cache
    @test cache_data[4] === g[4].cache
    @test cache_data[6] === g[6].cache

    cache_data = get_cache(g, 3) # will only get (2, phase)
    @test cache_data[2] === g[2].cache
    @test_throws KeyError cache_data[4]
    @test_throws KeyError cache_data[6]
end

@testset "cache" begin

    g = kron(phase(1.0), gate(X), phase(2.0))
    cached = cache(g)
    
    cache!(cached)
    @test length(get_cache(cached)) == 1 # will cache, first cache

    cache!(cached)
    @test length(get_cache(cached)) == 1 # nothing changed, will not cache

    update!(cached, 1=>0.2)
    cache!(cached) # parameter updated, will cache
    @test length(get_cache(cached)) == 2
    # default is a sparse matrix in CSC
    @test typeof(cached.cache[cached.block]) <: SparseMatrixCSC
end