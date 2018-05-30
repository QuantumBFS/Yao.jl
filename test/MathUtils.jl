using Compat.Test
using Yao
import Yao: log2i, bit_length


@testset "log2i" begin

    for itype in [
            Int8, Int16, Int32, Int64, Int128,
            UInt8, UInt16, UInt32, UInt64, UInt128,
        ]
        @test log2i(itype(2^5)) == 5
        @test typeof(log2i(itype(2^5))) == itype
    end
end

@testset "bit length" begin

    @test bit_length(8) == 4

end

@testset "batch normalize" begin
    s = rand(3, 4)
    batch_normalize!(s, 1)
    for i = 1:4
        @test sum(s[:, i]) ≈ 1
    end

    s = rand(3, 4)
    ss = batch_normalize(s, 1)
    for i = 1:4
        @test sum(s[:, i]) != 1
        @test sum(ss[:, i]) ≈ 1
    end
end

@testset "kronprod" begin
⊗ = kron
list = [rand(2, 2), rand(3, 3), rand(4, 4)]
@test kronprod(list) == list[1] ⊗ list[2] ⊗ list[3]
end
