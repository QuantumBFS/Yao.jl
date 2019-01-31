using Test, LinearAlgebra
using Yao, Yao.Blocks

@testset "add arithmatics" begin
    g1 = put(3, 1=>X)
    g2 = put(3, 2=>Y)
    g3 = put(3, 3=>Z)
    @test g1 + g2 == AddBlock(g1, g2)
    @test g1 + g2 + g3 == AddBlock(g1, g2, g3)
    B0 = (g1 + g2 + g3)
    B1 = 3*B0
    @test B1 isa Scale
    @test mat(B1) == 3*mat(B0)
    @test g1*(g3+g2) isa ChainBlock
    @test g1*(g3+g2) |> mat == mat(g1)*(mat(g2)+mat(g3))
    @test g1*g2 isa ChainBlock
    @test mat(g1*g2) ≈ mat(g1)*mat(g2)
    @test mat(g1*g2*g3) ≈ mat(g1)*mat(g2)*mat(g3)
    @test mat(g1*(g2*g3)) ≈ mat(g1)*mat(g2)*mat(g3)
    @test mat(2g1*(g2*g3)) ≈ 2*mat(g1)*mat(g2)*mat(g3)
    @test mat(g1*(2*(g2*g3))) ≈ 2*mat(g1)*mat(g2)*mat(g3)
    @test g1*g2 isa ChainBlock
    @test (g1*g2)*(g3+g2) |> mat |> Matrix ≈ Matrix(mat(g1)*mat(g2)*(mat(g2)+mat(g3)))
    @test (g1+g3)*(g3+g2) |> mat ≈ (mat(g1)+mat(g3))*(mat(g2)+mat(g3))

    @test mat(g1-g2) ≈ mat(g1+(-g2))
    @test mat(g1/2) ≈ mat(0.5*g1)
end
