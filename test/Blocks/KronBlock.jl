using Compat.Test

import QuCircuit: KronBlock
import QuCircuit: rand_state, state, focus!, X, Y, Z, gate, phase
# Block Trait
import QuCircuit: nqubit, ninput, noutput, isunitary, ispure
# Required Methods
import QuCircuit: apply!, dispatch!

⊗ = kron

@testset "contiguous" begin
    # default should organize this as
    # contiguous gates on address
    # -- [X] --
    # -- [Y] --
    # -- [Z] --
    g = kron(X(), Y(), Z())

    @test nqubit(g) == 3
    @test ninput(g) == 3
    @test noutput(g) == 3
    @test isunitary(g) == true
    @test ispure(g) == true

    # check matrix form
    mat = sparse(X()) ⊗ sparse(Y()) ⊗ sparse(Z())
    @test sparse(g) == mat
    @test full(g) == full(mat)

    reg = rand_state(3)
    @test full(g) * state(reg) == state(apply!(reg, g))

    # do nothing
    @test dispatch!(g) == g
end

@testset "mixin parameter" begin
    g = kron(phase(1.0), X(), phase(2.0))

    @test nqubit(g) == 3
    @test ninput(g) == 3
    @test noutput(g) == 3
    @test isunitary(g) == true
    @test ispure(g) == true

    mat = sparse(phase(1.0)) ⊗ sparse(X()) ⊗ sparse(phase(2.0))
    @test sparse(g) == mat
    @test full(g) == full(mat)

    # do nothing
    @test dispatch!(g) == g

    # update parameter
    dispatch!(g, [5.0, 5.0])
    @test g[1].theta == 5.0
    @test g[3].theta == 5.0
end

@testset "in-contiguous" begin

    g = kron(X(), (3, Z()), X())

    @test nqubit(g) == 4
    @test ninput(g) == 4
    @test noutput(g) == 4
    @test isunitary(g) == true
    @test ispure(g) == true

    mat = sparse(X()) ⊗ speye(2) ⊗ sparse(Z()) ⊗ sparse(X())
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
    @test ispure(g) == true

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
    @test ispure(g) == true

    blocks = collect(values(g))
    mat = sparse(blocks[1]) ⊗ speye(2) ⊗ sparse(blocks[2]) ⊗ speye(2) ⊗ sparse(blocks[3])
    @test sparse(g) == mat
    @test full(g) == full(mat)
end

@testset "manual total qubits" begin

    g = kron(2, X())
    @test nqubit(g) == 2
    mat = sparse(X()) ⊗ speye(2)
    @test sparse(g) == mat

    g = kron(5, X(), Y())

    @test nqubit(g) == 5
    @test ninput(g) == 5
    @test noutput(g) == 5
    @test isunitary(g) == true
    @test ispure(g) == true

    mat = sparse(X()) ⊗ sparse(Y()) ⊗ speye(8)
    @test sparse(g) == mat
    @test full(g) == full(mat)

    # check in-contiguous address from beginning
    g = kron(5, (2, X()), Y())

    @test nqubit(g) == 5

    mat = speye(2) ⊗ sparse(X()) ⊗ sparse(Y()) ⊗ speye(4)
    @test sparse(g) == mat
    @test full(g) == full(mat)
end
