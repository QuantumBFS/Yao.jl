import QuCircuit: AbstractGate, update!
using Compat.Test


struct TestGate{N} <: AbstractGate{N}
end


@testset "Test Default methods" begin
    gate = TestGate{4}()
    @test size(gate) == 4
    @test sparse(Float32, gate) == speye(Float32, 4)
    @test full(Float32, gate) == eye(Float32, 4)
    @test typeof(sparse(gate)) <: AbstractSparseMatrix
    @test typeof(full(gate)) <: AbstractMatrix

    # default eltype should be Complex128
    @test eltype(sparse(gate)) <: Complex128
    @test eltype(full(gate)) <: Complex128

    # check if eltype is tweakable
    @test eltype(sparse(Float32, gate)) <: Float32
    @test eltype(full(Float32, gate)) <: Float32

    # do nothing and return the original gate
    @test update!(gate, [1, 1, 1]) === gate

end
