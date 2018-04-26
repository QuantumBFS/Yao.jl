import QuCircuit: AbstractRegister, Register, data, nqubit, nbatch, pack!, focus
using Compat.Test

@testset "Constructors" begin

    @test typeof(Register(5, 2, rand(Complex128, 2^5, 2), collect(1:5))) == Register{5, 2, Complex128, 2}
    @test Register(5, 2, rand(Complex128, 2^5, 2)).ids == collect(1:5)
    @test nqubit(Register(2, rand(Complex128, 2^5, 2))) == 5
    @test nbatch(Register(rand(Complex128, 2^5))) == 1

    test_data = zeros(Complex64, 2, 2, 2, 2, 2, 3)
    @test Register(Complex64, 5, 2).ids == collect(1:5)
    @test Register(Complex64, 5, 3).data == test_data
    @test nbatch(Register(Complex64, 5)) == 1

    # check default type
    @test eltype(Register(5)) == Complex128
    @test eltype(Register(5, 2)) == Complex128
end

@testset "Dimension Permutation & Reshape" begin

    reg = Register(5)
    @test size(reshape(reg, 2^3, 2^2)) == (2^3, 2^2)
    dst = Register(5); src = Register(5)
    @test pack!(dst, src, (2, 3)) == dst
    @test dst.ids == [2, 3, 1, 4, 5]
    # (2, 3) should be equal to (3, 2)
    @test dst.ids == [2, 3, 1, 4, 5]

    out = focus(reg, (2, 3))
    @test out.ids == [2, 3, 1, 4, 5]
    @test size(out.data) == (2^2, 2^3)

    reg = Register(5, 3)
    out = focus(reg, (2, 3))
    @test out.ids == [2, 3, 1, 4, 5]
    @test size(out.data) == (2^2, 2^3, 3)
end
