using Compat.Test
using Compat
using QuCircuit

import QuCircuit: ConstGate, Val

@testset "constructor" begin
# we config default types in interface part
@test_throws MethodError ConstGate(:X)
for NAME in [:X, :Y, :Z, :H]
    @test isa(ConstGate(ComplexF64, NAME), ConstGate{1, Val{NAME}, ComplexF64})
end
@test isa(ConstGate(ComplexF32, :X), ConstGate{1, Val{:X}, ComplexF32})
end

@testset "traits" begin
g = ConstGate(ComplexF64, :X)
nqubit(g) == 1
ninput(g) == 1
noutput(g) == 1
isunitary(g) == true
ispure(g) == true
isreflexive(g) == true
ishermitian(g) == true
end

@testset "matrix" begin
# check matrixes
for (NAME, MAT) in [
    (:X, [0 1;1 0]),
    (:Y, [0 -im; im 0]),
    (:Z, [1 0;0 -1]),
    (:H, (elem = 1 / sqrt(2); [elem elem; elem -elem])),
]
    for DTYPE in [Compat.ComplexF16, Compat.ComplexF32, Compat.ComplexF64]
        @test full(ConstGate(DTYPE, NAME)) == Array{DTYPE, 2}(MAT)

        # all constant gates share the same constant matrix
        @test full(ConstGate(DTYPE, NAME)) === full(ConstGate(DTYPE, NAME))
        @test sparse(ConstGate(DTYPE, NAME)) === sparse(ConstGate(DTYPE, NAME))
    end
end
end

@testset "apply" begin
g = ConstGate(ComplexF64, :X)
reg = rand_state(4)
focus!(reg, 1)
# gates will be applied to register (by matrix multiplication)
# without any conversion by default
@test [0 1;1 0] * state(reg) == state(apply!(reg, g))
@test [0 1;1 0] * state(reg) == state(g(reg))
focus!(reg, 1:4) # back to vector
@test_throws DimensionMismatch apply!(reg, g)
end

@testset "compare" begin
# check compare method
# TODO: traverse all possible value
list = [:X, :Y, :Z, :H]
for (lhs, rhs) in zip(list, list)
    (ConstGate(ComplexF64, lhs) == ConstGate(ComplexF64, rhs)) == (lhs == rhs)
end
end
