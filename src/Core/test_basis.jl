######### Tests #########
using Compat.Test
include("basis.jl")

@testset "basis" begin
    # take bit
    @test takebit(12, 2) == 0
    @test takebit([12, 2], 2) == [0,1]
    @test takebit(12, [3,2]) == [1,0]

    # flip
    @test flip(12, 1) == 13
    @test flip(12, [1, 3]) == 9
    @test flip([12, 2], 2) == [14, 0]
    @test flip([12, 2], [2, 1]) == [15, 1]

    # indices_with
    nbit = 5
    indices = collect(0:(1<<nbit)-1)
    poss, vals = [4,2,3], [1,0,1]
    @test indices_with(nbit, poss, vals, indices) == filter(x-> takebit(x, poss) == vals, indices)
    @test indices_with(nbit, poss, vals, indices) == indices_with(nbit, poss, vals)
    @test _subspace(3, [1,3], 0) == [0, 1, 4, 5]

    # bitarray version
    # b - take bit
    ba1 = bitarray(12)
    ba2 = bitarray([12, 2])
    @test ba1[2, 1] == takebit(12, 2)
    @test ba1[[3, 2], 1] == takebit(12, [3, 2])
    @test ba2[2,:] == takebit([12, 2], 2)

    # b - flip
    #@test flipbits!(bitarray(12), 1) == 13
    #@test flipbits!(bitarray(12), [1, 3]) == 9
    #@test flipbits!(bitarray([12, 2]), 2) == [14, 0]
    #@test flipbits!(bitarray([12, 2]), [2, 1]) == [15, 1]
end
