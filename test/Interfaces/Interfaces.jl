using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.Blocks
using Yao.Intrinsics

@testset "phase gate" begin
    @test phase() isa PhaseGate{Float64}
    @test shift() isa ShiftGate{Float64}
    @test phase().theta == 0.0
end

@testset "chain" begin
    @test chain(X, Y, Z) isa ChainBlock
end

@testset "kron" begin
    # varargs construction
    @test kron(2, X, X) isa KronBlock
    # lazy construction
    @test kron(X, Y)(4) isa KronBlock
    # lazy construction (iterator)
    @test kron(X for i=1:4)(4) isa KronBlock
end

@testset "control" begin
    @test control(3, [1, 2], 3=>X) isa ControlBlock
    @test control(5, 1:2, 3=>X) isa ControlBlock

    @test (1=>X) |> control(8, i for i in [2, 3, 6, 7]) isa ControlBlock
    @test ((1=>X) |> control(i for i in [2, 3, 6, 7]))(8) isa ControlBlock

    @test ((1=>X) |> C(2, 3))(4) isa ControlBlock
end

@testset "roll" begin
    rr = rollrepeat(4, X)
    ro = roll(3, X, Y, Z)
    @test rr isa Roller
    @test usedbits(rr) == [1,2,3,4]
    @test ro isa Roller
    @test usedbits(ro) == [1,2,3]
    @test addrs(ro) == [1,2,3]
    r2 = rollrepeat(4, CNOT)
    @test addrs(r2) == [1,3]
    @test usedbits(r2) == [1,2, 3, 4]
    @test_throws AddressConflictError rollrepeat(3, CNOT)
end

@testset "measure" begin
    @test MEASURE isa Measure
    @test MEASURE_REMOVE isa MeasureAndRemove
end

@testset "concentrate" begin
    r = rollrepeat(4, X)
    @test concentrate(8, r, [6, 1, 2, 3]) isa Concentrator
end

@testset "signal" begin
    @test signal(2) isa Signal
    @test signal(2).sig == 2
end

@testset "pauli gates binding" begin
    @test X isa XGate{ComplexF64}
end

@testset "gate" begin
    @test X isa XGate{ComplexF64}
    @test X(ComplexF32) isa XGate{ComplexF32}
    @test Rx(1) isa RotationGate
    @test Ry(1) isa RotationGate
    @test Rz(1) isa RotationGate
end
