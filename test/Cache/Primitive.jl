using Compat.Test

import QuCircuit: cache_type, cache_matrix, object_hash, param_hash

import QuCircuit: X, Y, Z, Hadmard
import QuCircuit: gate, phase, rot
import QuCircuit: cache, update_cache, pull
import QuCircuit: dispatch!

function std_cache_test(f::Function, g)
    cache(g, 2)
    update_cache(g, 3)
    @test pull(g) == sparse(g)

    f(g)
    @test_throws KeyError pull(g)

    update_cache(g, 1) # signal is lower than level
    @test_throws KeyError pull(g)
    update_cache(g, 3)
    @test pull(g) == sparse(g)    
end

@testset "basic gate" begin

    @testset "constant gate" begin
        for each in [X, Y, Z, Hadmard]

            local g
            g = gate(each)
            # default cache type
            @test cache_type(g) == SparseMatrixCSC{Complex128, Int}
            @test cache_matrix(g) == sparse(g)

            # cache id
            @test object_hash(g) == object_id(g)
            # parameter id
            @test param_hash(g) == hash(g)

            cache(g, 2)
            update_cache(g, 3)
            # basic gate cache will not allocate
            # new memory
            @test pull(g) === sparse(g)

        end
    end

    @testset "phase gate" begin
        g = phase(0.1)
        std_cache_test(x->dispatch!(x, 0.2), g)
    end

    @testset "rotation" begin
        g = rot(X, 0.1)
        std_cache_test(x->dispatch!(x, 0.2), g)
    end
end

# TODO: Control Gate
