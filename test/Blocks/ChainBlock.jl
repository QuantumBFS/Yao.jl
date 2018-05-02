using Compat.Test

import QuCircuit: ChainBlock
import QuCircuit: Cache, rand_state, state, focus!,
    X, Y, Z, gate, phase, cache, focus, address
# Interface
import QuCircuit: chain
# Block Trait
import QuCircuit: nqubit, ninput, noutput, isunitary,
                iscacheable, cache_type, ispure, get_cache
# Required Methods
import QuCircuit: apply!, update!, cache!


@testset "chain pure" begin
    g = chain(
        2,
        kron(gate(X), gate(Y)),
        kron(2, gate(Complex64, Z))
    )

    @test eltype(g) <: Complex128
    @test nqubit(g) == 2
    @test ninput(g) == 2
    @test noutput(g) == 2
    @test isunitary(g) == true
    @test iscacheable(g) == true
    @test cache_type(g) == Cache
    @test ispure(g) == true
    @test get_cache(g) == Dict()

    mat = kron(sparse(gate(Complex64, Z)), speye(2)) * kron(sparse(gate(X)), sparse(gate(Y)))
    @test sparse(g) == mat
    @test full(g) == full(mat)

    reg = rand_state(2)
    @test mat * state(reg) == state(apply!(reg, g))
end

@testset "chain focus" begin

    g = chain(
        5,
        focus(2, 3),
        kron(gate(X), gate(Y)),
        focus(1:5)
    )

    @test eltype(g) <: Complex128
    @test nqubit(g) == 5
    @test ninput(g) == 5
    @test noutput(g) == 5
    @test isunitary(g) == true
    @test iscacheable(g) == true
    @test cache_type(g) == Cache
    @test ispure(g) == true
    @test get_cache(g) == Dict()

    # ! matrix format is not implemented

    reg_a = rand_state(5)
    reg_b = copy(reg_a)

    focus!(reg_a, 2, 3)
    apply!(reg_a, kron(gate(X), gate(Y)))
    focus!(reg_a, 1:5)

    apply!(reg_b, g)
    @test state(reg_a) == state(reg_b)
    @test address(reg_a) == address(reg_b)

    g = chain(5, focus(2, 3), kron(gate(X), gate(Y)))

    @test eltype(g) <: Complex128
    @test nqubit(g) == 5
    @test ninput(g) == 5
    @test noutput(g) == 5
    @test isunitary(g) == true
    @test iscacheable(g) == true
    @test cache_type(g) == Cache
    @test ispure(g) == true
    @test get_cache(g) == Dict()

    reg_a = rand_state(5)
    reg_b = copy(reg_a)

    focus!(reg_a, 2, 3)
    apply!(reg_a, kron(gate(X), gate(Y)))
    focus!(reg_a, 1:5)

    apply!(reg_b, g)
    @test state(reg_a) == state(reg_b)
    @test address(reg_a) == address(reg_b)

end
