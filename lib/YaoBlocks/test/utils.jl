using YaoBlocks
using YaoBlocks: sprand_hermitian, sprand_unitary
using SparseArrays: sparse
using BitBasis
using Test

@testset "random matrices" begin
    mat = rand_unitary(8)
    @test isunitary(mat)
    mat = rand_hermitian(8)
    @test ishermitian(mat)

    @test ishermitian(sprand_hermitian(8, 0.5))
    @test isunitary(sprand_unitary(8, 0.5))
end

@testset "projector" begin
    @test projector(0) ≈ [1 0; 0 0]
    @test projector(1) ≈ [0 0; 0 1]
end

@testset "entry table" begin
    for table in [EntryTable(BitStr64{3}[], ComplexF64[]),
        EntryTable([bit"000", bit"101", bit"001", bit"101", bit"101", bit"000"], randn(ComplexF64, 6))
        ]
        @test vec(table) == sparse(table)
        @test vec(table) == vec(cleanup(table))
        println(table)
    end
    e1 = EntryTable([bit"001"], [2.0])
    @test merge(e1,e1,e1) == EntryTable([bit"001",bit"001",bit"001"], fill(2.0, 3))

    # case 1, has zero values
    @test !isclean(EntryTable([bit"110", bit"111"], [0.0im, 0.1]))
    # case 2, has duplicated entries
    @test !isclean(EntryTable([bit"110", bit"110"], [1.0im, 0.1]))
    # case 3, has inversed order
    @test !isclean(EntryTable([bit"111", bit"110"], [0.0im, 0.1]))

    et = EntryTable([bit"000",bit"011",bit"101",bit"101",bit"011",bit"110",bit"110",bit"011",], [1.0 + 0.0im,-1, 1,1,1,-1,1,1,-1])
    @test_throws ErrorException et[bit"000"]
    @test !isclean(et)
    cet = cleanup(et)
    @test cet |> length == 3
    @test isclean(cet)
    @test cet[bit"000"] == 1.0+0im
    @test cet[bit"111"] == 0.0im
end