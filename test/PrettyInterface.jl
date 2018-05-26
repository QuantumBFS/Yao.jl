using Compat
using Compat.Test
using QuCircuit
import QuCircuit: Gate, ChainBlock, KronBlock, ControlBlock, Roller,
    Measure, MeasureAndRemove, Concentrator, Signal, RotationGate
import QuCircuit: PhiGate

@testset "phase gate" begin
    @test isa(phase(), PhiGate)
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
    @test isa(X(), Gate{1, Val{:X}, ComplexF64})
    @test isa(X(2), Tuple)
    @test isa(X(1:3), Tuple)
    @test isa(X(4, 2), KronBlock)
    @test isa(X(4, 1:3), KronBlock)
end

@testset "gate" begin
    @test isa(gate(:X), Gate{1, Val{:X}, ComplexF64})
    @test isa(gate(ComplexF32, :X), Gate{1, Val{:X}, ComplexF32})
    @test isa(gate(ComplexF64, :Rx, 1), RotationGate)
    @test isa(gate(ComplexF64, :Ry, 1), RotationGate)
    @test isa(gate(ComplexF64, :Rz, 1), RotationGate)
    @test isa(gate(ComplexF64, :Ra, 1, 2, 3), ChainBlock)
end
