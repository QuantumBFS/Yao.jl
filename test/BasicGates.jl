import QuCircuit: X, Y, Z, H, CNOT, gate, Gate, apply!, register
import QuCircuit.Routine: OOO, Rand
using Compat.Test

@testset "Test constructor" begin

    # single qubit gate
    for each in [X, Y, Z, H]
        @test typeof(gate(each)) == Gate{each, 1}
        @test typeof(full(gate(each))) <: DenseMatrix
    end

    @test typeof(gate(CNOT)) == Gate{CNOT, 2}
    @test typeof(full(gate(CNOT))) <: DenseMatrix

end

@testset "Test apply" begin

    for each in [X, Y, Z]
        reg = register(rand(Complex128, 16))
        t_reg = copy(reg)
        g = gate(each)
        apply!(g, reg, 2)
        I = [1 0;0 1]
        @test kron(kron(kron(I, I), sparse(g)), I) * t_reg.state == reg.state
    end
end
