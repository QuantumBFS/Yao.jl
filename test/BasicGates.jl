import QuCircuit: X, Y, Z, H, CNOT, gate, Gate
using Compat.Test

@testset "Test constructor" begin

    # single qubit gate
    for each in [X, Y, Z, H]
        @test typeof(gate(each)) == Gate{each, 1}
        @test typeof(full(gate(each))) <: DenseMatrix
    end

end