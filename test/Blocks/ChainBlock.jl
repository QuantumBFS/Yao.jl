using Compat.Test
using QuCircuit

import QuCircuit: ChainBlock
import QuCircuit: rand_state, state, focus!,
    X, Y, Z, gate, phase, focus, address, rot
# Block Trait
import QuCircuit: nqubit, ninput, noutput, isunitary, ispure
# Required Methods
import QuCircuit: apply!, dispatch!

@testset "chain" begin
    g = ChainBlock(
        kron(2, X(), Y()),
        kron(2, phase(0.1)),
    )

    mat = sparse(kron(2, phase(0.1))) * sparse(kron(2, X(), Y()))
    @test sparse(g) == mat
end

# @testset "chain pure" begin

#     g = chain(
#         kron(X(), Y()),
#         kron(2, gate(Complex64, :Z))
#     )

#     @test nqubit(g) == 2
#     @test ninput(g) == 2
#     @test noutput(g) == 2
#     @test isunitary(g) == true
#     @test ispure(g) == true

#     mat = kron(sparse(gate(Complex64, :Z)), speye(2)) * kron(sparse(X()), sparse(Y()))
#     @test sparse(g) == mat
#     @test full(g) == full(mat)

#     reg = rand_state(2)
#     @test mat * state(reg) == state(apply!(reg, g))

#     # check call method
#     @test mat * state(reg) == state(g(reg))

#     # check copy
#     cg = copy(g)
#     for (copied, original) in zip(cg.blocks, g.blocks)
#         @test copied !== original
#         @test copied == original
#     end
# end

# @testset "parameter chain" begin

#     g = chain(
#         phase(0.2),
#         rot(:X, 0.1),
#     )

#     dispatch!(g, [0.3, 0.5])
#     @test g.blocks[1].theta == 0.3
#     @test g.blocks[2].theta == 0.5
# end
