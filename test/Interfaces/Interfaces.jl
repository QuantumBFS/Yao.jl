using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.Blocks
using Yao.Intrinsics

@testset "with context" begin
    r = register(bit"00000")
    with!(r) do r
        r |> chain(repeat(X), kron(3=>Y))
        r |> roll(1=>phase(0.1))
    end
    @test statevec(r) != statevec(register(bit"000000"))

    r = register(bit"0000")
    with(r) do r
        r |> chain(4, repeat(X))
    end

    @test statevec(r) ≈ statevec(register(bit"0000"))

    r = register(bit"0000")
    with(repeat(4, X), r)
    @test statevec(r) ≈ statevec(register(bit"0000"))

    with!(repeat(4, X), r)
    @test statevec(r) ≈ statevec(register(bit"1111"))
end

@testset "phase gate" begin
    @test phase(0.0) isa PhaseGate{Float64}
    @test shift(0.0) isa ShiftGate{Float64}
    @test phase(0.0).theta == 0.0
end

@testset "reflect gate" begin
    psi = rand_state(5)
    @test reflect(psi) isa ReflectBlock
    @test reflect(psi |> statevec) isa ReflectBlock
end

@testset "matrix gate" begin
    matrix = randn(4,8)
    @test matrixgate(matrix) isa GeneralMatrixGate
    @test matrixgate(matrix) isa GeneralMatrixGate
    matrix = randn(4,7)
    @test_throws DimensionMismatch matrixgate(matrix)
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

@testset "put" begin
    # varargs construction
    @test_throws AddressConflictError put(2, (3,2)=>CNOT)
    @test put(5, (3,2)=>CNOT) isa PutBlock
    @test put(5, 3=>X) isa PutBlock
    println(put(5, (3,2)=>CNOT))
    # lazy construction
    @test put(3=>X)(4) isa PutBlock
    @test_throws MethodError put((3,3)=>X)(4)
end


@testset "control" begin
    @test control(3, [1, 2], 3=>X) isa ControlBlock
    @test control(5, 1:2, 3=>X) isa ControlBlock

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

@testset "functions" begin
    reg = rand_state(3, 2)
    @test InvOrder isa FunctionBlock{:InvOrder}
    @test apply!(copy(reg), InvOrder) == copy(reg) |> invorder!

    @test addbit(3) isa FunctionBlock{Tuple{:AddBit, 3}}
    @test apply!(copy(reg), addbit(2)) |> state == kron(zero_state(2) |> state, reg |> state)

    Probs = @fn probs
    @test Probs isa FunctionBlock{typeof(probs)}
    @test apply!(copy(reg), Probs) == reg |> probs

    FB = focus(1,3,2)
    @test copy(reg) |> FB == focus!(copy(reg), [1,3,2])
end

@testset "sequence" begin
    sq = sequence(kron(3=>X), addbit(3), MEASURE)
    @test sq isa Function
    sqs = sq(5)
    @test sqs isa Sequential
    @test sqs == sequence(kron(5, 3=>X), addbit(3), MEASURE) == sequence((kron(5, 3=>X), addbit(3), MEASURE))
    insert!(sqs, 3, kron(8, 8=>X))
    push!(sqs, Reset)
    reg = register(bit"11111") |> sqs
    @test MEASURE.result[] == 155
    @test reg == zero_state(8)
    reg = register(bit"11111") |> sqs[1:end-1]
    @test MEASURE.result[] == 155
    @test reg != zero_state(8)
end
