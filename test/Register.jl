import QuCircuit: AbstractRegister, ClassicalRegister, state, register
import QuCircuit.Routine: GHZ, OOO, Rand
using Compat.Test

@testset "Test Classical Register" begin

    @test ClassicalRegister <: AbstractRegister
    @test state(register(GHZ, 3)) == normalize([1, 0, 0, 0, 0, 0, 0, 1])
    @test eltype(state(register(Complex64, GHZ, 3))) == Complex64

    @test state(register(OOO, 3)) == normalize([1, 0, 0, 0, 0, 0, 0, 0])
    @test eltype(state(register(Complex64, OOO, 3))) == Complex64
end
