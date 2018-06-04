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
    # b - take bit
    ba1 = bitarray(ind)
    ba2 = bitarray(inds)
    @test ba1[2, 1] == takebit(ind, 2)
    @test ba1[[3, 2], 1] == takebit.(ind, [3, 2])
    @test ba2[2,:] == takebit.([ind, 2], 2)

    # b - flip
    #@test flipbits!(bitarray(12), 1) == 13
    #@test flipbits!(bitarray(12), [1, 3]) == 9
    #@test flipbits!(bitarray([12, 2]), 2) == [14, 0]
    #@test flipbits!(bitarray([12, 2]), [2, 1]) == [15, 1]
end

#= No Longer supported
@testset "state" begin
    q = ghz(3)
    p = onehot(3, UInt(0))
    @test isapprox(p, vcat([1],zeros(7)))
    @test isapprox(q, vcat([1/sqrt(2)],zeros(6), [1/sqrt(2)]))
end
=#
