using Test
using BitBasis
using Yao.EasyBuild
using Yao.EasyBuild: pattern53, upperright, lowerleft, upperleft, lowerright
using YaoBlocks.Optimise: to_basictypes, simplify, replace_block

lattice = Lattice53()
@test upperright(lattice,1,1) == 0
@test upperright(lattice,2,1) == lattice[1,2]
@test upperright(lattice,1,2) == lattice[1,3]
@test lowerright(lattice,1,1) == lattice[1,2]
@test lowerright(lattice,1,2) == lattice[2,3]
@test upperleft(lattice,1,2) == lattice[1,1]
@test upperleft(lattice,1,3) == 0
@test upperleft(lattice,2,3) == lattice[1,2]
@test lowerleft(lattice,1,2) == lattice[2,1]
@test lowerleft(lattice,2,3) == lattice[2,2]

lattice = Lattice53()
for (sym, nvar) in [('A', 24), ('B', 19), ('C', 23), ('D', 20),
                    ('E', 22), ('F', 21), ('G', 21), ('H', 22)]
    @test length(pattern53(lattice, sym)) == nvar
end

@testset "circuit build" begin
    c = rand_google53(4)
    @test length(collect_blocks(FSimGate, c)) == 86
    @test nparameters(c) == 86*2
    @test length(collect_blocks(PrimitiveBlock{1}, c)) == 53*4
end
