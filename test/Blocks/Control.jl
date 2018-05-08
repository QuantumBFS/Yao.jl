using Compat.Test

import QuCircuit: zero_state, state, focus!,
    X, Y, Z, gate, phase, focus, address, rot
import QuCircuit: control
import QuCircuit: nqubit, ninput, noutput, isunitary, ispure
import QuCircuit: apply!, dispatch!

@testset "test control" begin

    # CNOT
    CNOT = control(1, gate(X), 2)
    @test full(CNOT) == Complex128[
        1 0 0 0
        0 1 0 0
        0 0 0 1
        0 0 1 0]

    @test eltype(CNOT) <: Complex128
    @test nqubit(CNOT) == 2
    @test ninput(CNOT) == 2
    @test noutput(CNOT) == 2
    @test isunitary(CNOT) == true
    @test ispure(CNOT) = true

    CONTROL_PHASE = control(1, phase(0.1), 2)
    @test norm(full(CONTROL_PHASE) - Complex128[
        1.0 0.0 0.0 0.0
        0.0 1.0 0.0 0.0
        0.0 0.0 1.0 0.0
        0.0 0.0 0.0 0.980067+0.198669im
    ]) < 1e-6

    # Inverse CNOT
    iCNOT = control(2, gate(X), 1)
    reg = zero_state(2)
    reg.state[2] = 1
    reg.state[1] = 0
    iCNOT(reg)
    @test reg.state[end] == 1
end
