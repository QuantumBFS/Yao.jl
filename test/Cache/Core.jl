using Compat.Test

import QuCircuit: iscacheable, CacheElement, pull, setlevel!

import QuCircuit: gate, X, Y, Z, H # constant
import QuCircuit: phase # parameter
import QuCircuit: kron, control, chain # composite

@testset "cache element" begin

    cache = CacheElement(Matrix{Complex128}, unsigned(3))
    @test iscacheable(cache, unsigned(3)) == false
    @test iscacheable(cache, unsigned(4)) == true

    push!(cache, gate(X), full(gate(X)), unsigned(3)) # cache nothing
    @test (hash(gate(X)) in keys(cache.data)) == false

    push!(cache, gate(X), full(gate(X)), unsigned(4))
    @test pull(cache, gate(X)) == full(gate(X))

    setlevel!(cache, unsigned(2))
    empty!(cache)
    push!(cache, gate(X), full(gate(X)), unsigned(3))
    @test pull(cache, gate(X)) == full(gate(X))
end

import QuCircuit: CacheServer, cache!


@testset "cache server" begin
    server = CacheServer(SparseMatrixCSC{Complex128, Int})

    glist = [
        gate(X),
        phase(0.1),
        kron(phase(0.1), gate(X)),
        chain(phase(0.1), gate(X)),
    ]

    # constant gates
    cache!(server, glist[1], unsigned(2))

    # parameterized gates
    cache!(server, glist[2], unsigned(3))

    # composite gates
    cache!(server, glist[3], unsigned(4))
    cache!(server, glist[4], unsigned(5))

    # won't cache
    for i = 1:4
        push!(server, glist[i], sparse(glist[i]), unsigned(i+1))
    end

    for i = 1:4
        @test_throws KeyError pull(server, glist[i])
    end

    # will cache

    for i = 1:4
        push!(server, glist[i], sparse(glist[i]), unsigned(i+2))
    end

    for i = 1:4
        @test pull(server, glist[i]) == sparse(glist[i])
    end
end

# check interface
import QuCircuit: cache, update_cache, pull

@testset "cache block" begin

    cached = cache(phase(0.1), 2)
    update_cache(cached, 2) # do nothing
    update_cache(cached, 3) # update
    pull(cached) # get the matrix

end
