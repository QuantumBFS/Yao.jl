using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks
import Yao.Blocks: Daggered

@testset "adjoint" begin
    @test adjoint(X) isa XGate
    @test adjoint(Pu) isa PdGate
    @test adjoint(chain(X, Y)) == chain(Y, X)
    @test mat(adjoint(chain(X, Y))) == mat(chain(Y, X))
    @test adjoint(kron(3, 2=>rot(X, 0.5))) == kron(3, 2=>rot(X, -0.5))
    @test mat(adjoint(kron(3, 2=>rot(X, 0.5)))) == mat(kron(3, 2=>rot(X, -0.5)))
    @test adjoint(kron(3, 2=>X)) == kron(3, 2=>X)
    @test mat(adjoint(kron(3, 2=>X))) == mat(kron(3, 2=>X))
    @test adjoint(repeat(3, Pu, (3,1))) == repeat(3, Pd, (3,1))
    @test mat(adjoint(repeat(3, Pu, (3,1)))) == mat(repeat(3, Pd, (3,1)))
    @test adjoint(repeat(3, X, (2,))) == repeat(3, X, (2,))
    @test mat(adjoint(repeat(3, X, (2,)))) == mat(repeat(3, X, (2,)))
    @test adjoint(concentrate(4, roll(3, ShiftGate(0.2), Pu, Z), [2,1,3])) == concentrate(4, roll(3, ShiftGate(-0.2), Pd, Z), [2,1,3])
    @test adjoint(control(4, 4, 1=>H)) == control(4, 4, 1=>H)
    @test mat(adjoint(control(4, 4, 1=>H))) == mat(control(4, 4, 1=>H))
    @test adjoint(control(4, 4, 1=>PhaseGate(0.5))) == control(4, 4, 1=>PhaseGate(-0.5))
    @test mat(adjoint(control(4, 4, 1=>PhaseGate(0.5)))) == mat(control(4, 4, 1=>PhaseGate(-0.5)))
    @test adjoint(put(4, 1=>PhaseGate(0.5))) == put(4, 1=>PhaseGate(-0.5))
    @test mat(adjoint(put(4, 1=>PhaseGate(0.5)))) == mat(put(4, 1=>PhaseGate(-0.5)))
end

@testset "mat, adjoint^2" begin
    # construct a constant gate and get its mat
    @const_gate ConstG = [0 im; im 0]
    GP = adjoint(ConstG)
    @test GP != ConstG
    @test GP isa Daggered
    @test mat(GP) == mat(ConstG)'
    @test adjoint(adjoint(ConstG)) === ConstG
end

@testset "copy dispatch" begin
    pg = adjoint(PhaseGate(0.4))
    cpg = copy(pg)
    @test pg == cpg
    dispatch!(pg, [0.8])
    @test pg != cpg
end
