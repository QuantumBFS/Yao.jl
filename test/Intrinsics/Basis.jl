######### Tests #########
using Compat.Test
using Compat.Iterators

using Yao
using Yao.Intrinsics

@testset "basis" begin
    # take bit
    ind = DInt(12)
    inds = DInt[12, 2]
    @test takebit(ind, 2) == 0
    @test takebit.([ind, 2], 2) == [0,1]
    @test takebit.(ind, [3,2]) == [1,0]

    # flip
    @test flip(ind, bmask(1)) == 13
    @test flip(ind, bmask(1, 3)) == 9
    @test flip.(inds, bmask(2)) == [14, 0]
    @test flip.(inds, bmask(2, 1)) == [15, 1]

    # indices_with
    nbit = 5
    poss, vals = [4,2,3], [1,0,1]
    @test indices_with(nbit, poss, vals) == filter(x-> takebit.(x, poss) == vals, basis(nbit))

    # bitarray version
    # b - bitarray and take bit
    ba1_f = bitarray(ind)
    ba2_f = bitarray(inds)
    @test bsizeof(ind) == 64
    @test size(ba1_f) == (64,)
    @test size(ba2_f) == (64, 2)

    ba1 = bitarray(ind, num_bit=4)
    ba2 = bitarray(inds, num_bit=4)
    @test size(ba1) == (4,)
    @test size(ba2) == (4, 2)

    @test ba1[2, 1] == takebit(ind, 2)
    @test ba1[[3, 2], 1] == takebit.(ind, [3, 2])
    @test ba2[2,:] == takebit.([ind, 2], 2)

    # b - flip
    #@test flipbits!(bitarray(12), 1) == 13
    #@test flipbits!(bitarray(12), [1, 3]) == 9
    #@test flipbits!(bitarray([12, 2]), 2) == [14, 0]
    #@test flipbits!(bitarray([12, 2]), [2, 1]) == [15, 1]
end

@testset "SwapBits" begin
    msk = bmask(2,5)
    @test swapbits(7, msk) == 21
end

@testset "EasyBasis" begin
    @test bdistance(1,7) == 2
    @test bitarray(2, num_bit=4) == [false, true, false, false]
    @test packbits(BitArray([true, true, true])) == 7

    @test packbits(bitarray(3, num_bit=10)) == 3
    @test packbits(bitarray([5,3,7,21], num_bit=10)) == [5, 3, 7, 21]
end


