using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
import Yao: ChainBlock, KronBlock, ControlBlock, Roller,
    Measure, MeasureAndRemove, Concentrator, Signal, RotationGate
import Yao: PhaseGate, RangedBlock

@testset "phase gate" begin
    @test isa(phase(), PhaseGate{:global, Float64})
    @test isa(shift(), PhaseGate{:shift, Float64})
    @test phase().theta == 0.0
end

@testset "chain" begin
    @test isa(chain(X(), Y(), Z()), ChainBlock)
    @test isa(chain[X(), Y()], ChainBlock)
end

@testset "kron" begin
    # varargs construction
    @test isa(kron(2, X(), X()), KronBlock)
    # lazy construction
    @test isa(kron(X(), Y())(4), KronBlock)
    # lazy construction (iterator)
    @test isa(kron(X() for i=1:4)(4), KronBlock)
end

@testset "control" begin
    @test isa(control(3, [1, 2], X(), 3), ControlBlock)
    @test isa(control(5, 1:2, X(), 3), ControlBlock)

    @test isa(X(1) |> control(5, i for i in [2, 3, 6, 7]), ControlBlock)
    @test isa(X(1) |> control(i for i in [2, 3, 6, 7]), ControlBlock)

    @test isa((X(1) |> C(2, 3))(4), ControlBlock)
end

@testset "roll" begin
    @test isa(roll(4, X()), Roller)
    @test isa(roll(X())(4), Roller)
    @test isa(roll(X(), Y(), Z()), Roller)
    @test isa(roll(X())(4), Roller)
end

@testset "measure" begin
    @test isa(measure(2), Measure{2})
    @test isa(measure_remove(2), MeasureAndRemove{2})
end

@testset "focus" begin
    @test isa(focus(1, 2, 3), Concentrator)
end

@testset "signal" begin
    @test isa(signal(2), Signal)
    @test signal(2).sig == 2
end

@testset "pauli gates binding" begin
    @test isa(X(), XGate{ComplexF64})
    @test isa(X(2), RangedBlock)
    @test isa(X(1:3), RangedBlock)
    @test isa(X(4, 2), KronBlock)
    @test isa(X(4, 1:3), KronBlock)
end

@testset "gate" begin
    @test isa(X, XGate{ComplexF64})
    @test isa(X(ComplexF32), XGate{ComplexF32})
    @test isa(Rx(1), RotationGate)
    @test isa(Ry(1), RotationGate)
    @test isa(Rz(1), RotationGate)
end
