import QuCircuit: AbstractRegister, Register
import QuCircuit: qubits, state, statevec, nqubit, nbatch, pack!, focus, view_batch
import Compat: axes
using Compat.Test

@testset "Constructors" begin

    @test typeof(Register(5, 2, rand(Complex128, 2^5, 2), collect(1:5))) == Register{5, 2, Complex128, 2}
    @test Register(5, 2, rand(Complex128, 2^5, 2)).ids == collect(1:5)
    @test nqubit(Register(2, rand(Complex128, 2^5, 2))) == 5
    @test nbatch(Register(rand(Complex128, 2^5))) == 1

    test_state = zeros(Complex64, 2, 2, 2, 2, 2, 3)
    @test Register(Complex64, 5, 2).ids == collect(1:5)
    @test state(Register(Complex64, 5, 3)) == test_state
    @test nbatch(Register(Complex64, 5)) == 1

    # check default type
    @test eltype(Register(5)) == Complex128
    @test eltype(Register(5, 2)) == Complex128
end

@testset "AbstractRegister Interface" begin
    reg = Register(5, 3)
    @test size(view_batch(reg, 1)) == (2, 2, 2, 2, 2)
    @test size(statevec(reg)) == (2^5, 3)
end

@testset "AbstractArray Interface" begin
    reg = Register(5, 3)
    @test eltype(reg) == eltype(state(reg))
    @test length(reg) == length(state(reg))
    @test ndims(reg) == ndims(state(reg))
    @test size(reg) == size(state(reg))
    @test size(reg, 2) == size(state(reg), 2)
    @test axes(reg, 2) == axes(state(reg), 2)
    @test axes(reg) == axes(state(reg))
    @test stride(reg, 2) == stride(state(reg), 2)
    @test strides(reg) == strides(state(reg))
    @test getindex(reg, (1, 1, 1, 1, 1, 2)) == getindex(state(reg), 1, 1, 1, 1, 1, 2)
    @test typeof(setindex!(reg, im, (1, 1, 1, 1, 1, 2))) == typeof(reg)
    @test typeof(setindex!(reg, im, 1, 1, 1, 1, 1, 2)) == typeof(reg)
    @test copy(reg).state !== reg.state
end

@testset "Batch Iterator" begin
    reg = Register(5, 3)
    for each in batch(reg)
        @test size(each) == (2, 2, 2, 2, 2)
    end

    @test length(batch(reg)) == 3
end

@testset "Dimension Permutation & Reshape" begin

    # conanical shape
    reg = Register(5)
    @test size(reshape(reg, 2^3, 2^2)) == (2^3, 2^2)
    dst = Register(5); src = Register(5)
    @test pack!(dst, src, (2, 3)) == dst
    @test qubits(dst) == [2, 3, 1, 4, 5]
    # (2, 3) should be equal to (3, 2)
    @test dst.ids == [2, 3, 1, 4, 5]

    out = focus(reg, (2, 3))
    @test out.ids == [2, 3, 1, 4, 5]
    @test size(out.state) == (2^2, 2^3)

    reg = Register(5, 3)
    out = focus(reg, (2, 3))
    @test out.ids == [2, 3, 1, 4, 5]
    @test size(out.state) == (2^2, 2^3, 3)

    # other shape
    reg = Register(rand(Complex128, 2^5))
    @test_throws AssertionError pack!(reg, reg, (2, 3))
end
