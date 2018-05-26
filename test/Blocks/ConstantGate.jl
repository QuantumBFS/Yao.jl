using Compat.Test
using Compat
using QuCircuit

import QuCircuit: Gate, Val

@testset "constructor" begin
# we config default types in interface part
@test_throws MethodError Gate(:X)
for NAME in [:X, :Y, :Z, :H]
    @test isa(Gate(ComplexF64, NAME), Gate{1, Val{NAME}, ComplexF64})
end
@test isa(Gate(ComplexF32, :X), Gate{1, Val{:X}, ComplexF32})
end

@testset "traits" begin
g = Gate(ComplexF64, :X)
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
        @test full(Gate(DTYPE, NAME)) == Array{DTYPE, 2}(MAT)

        # all constant gates share the same constant matrix
        @test full(Gate(DTYPE, NAME)) === full(Gate(DTYPE, NAME))
        @test sparse(Gate(DTYPE, NAME)) === sparse(Gate(DTYPE, NAME))
    end
end
end

@testset "apply" begin
g = Gate(ComplexF64, :X)
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
    (Gate(ComplexF64, lhs) == Gate(ComplexF64, rhs)) == (lhs == rhs)
end
end
