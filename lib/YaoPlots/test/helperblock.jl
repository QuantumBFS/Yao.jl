using YaoPlots, YaoBlocks, Luxor
using YaoArrayRegister
using Test

@testset "LabelBlock" begin
    x = put(5, (2,3)=>matblock(rand_unitary(4)))
    cb = LabelBlock(x, "x", "red", "")
    @test mat(copy(cb)) == mat(cb)
    @test isunitary(cb)
    @test ishermitian(cb) == ishermitian(x)
    @test isreflexive(cb) == isreflexive(x)
    @test mat(cb) == mat(x)
    reg = rand_state(5)
    @test apply!(copy(reg), cb) ≈ apply!(copy(reg), x)
    @test cb' isa LabelBlock && mat(cb') ≈ mat(cb)'
    @test (cb').name == "x†" && (cb'').name == "x"

    y = put(5, (3,4)=>matblock(rand_unitary(4)))
    cc = chsubblocks(cb, y)
    @test YaoPlots.is_continuous_chunk([1,2,3]) == true
    @test YaoPlots.is_continuous_chunk([1,2,4]) == false
    @test YaoPlots.is_continuous_chunk([3,2,4]) == true
    
    c1 = chain(5, [put(5, (2,3)=>addlabel(SWAP; name="SWAP")), put(5, 2=>addlabel(I2; name="id")), put(5, 2=>addlabel(X; name="X")), control(5, (5,3), (2,4,1)=>put(3, (1,3)=>addlabel(SWAP; name="SWAP")))])
    c2 = chain(5, [put(5, (2,3)=>addlabel(SWAP; name="SWAP")), put(5, 2=>addlabel(I2; name="id")), put(5, 2=>addlabel(X; name="X")), control(5, (5,3), (2,4,1)=>put(3, (1,2)=>addlabel(SWAP; name="SWAP")))])

    @test vizcircuit(c1) isa Drawing
    @test vizcircuit(c2) isa Drawing
end

@testset "annotate line" begin
    ann = line_annotation("test"; color="red")
    @test ann isa LineAnnotation
    c = chain(put(5, 2=>X), put(5, 2=>ann),  put(5, 3=>Y))
    @test vizcircuit(c) isa Drawing
end