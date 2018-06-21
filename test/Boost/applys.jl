using Compat
using Compat.Test
using Yao
using Yao.Boost
using Yao.Blocks
using Yao.Intrinsics
using Yao.LuxurySparse

@testset "xyz" begin
    @test linop2dense(s->xapply!(s, [1]), 1) == mat(X)
    @test linop2dense(s->yapply!(s, [1]), 1) == mat(Y)
    @test linop2dense(s->zapply!(s, [1]), 1) == mat(Z)

    @test linop2dense(s->cxapply!(s, 2, 1, 1), 2) == mat(control(2, 2, 1=>X))
    @test linop2dense(s->cyapply!(s, 2, 1, 1), 2) == mat(control(2, 2, 1=>Y))
    @test linop2dense(s->czapply!(s, 2, 1, 1), 2) == mat(control(2, 2, 1=>Z))

    @test linop2dense(s->cxapply!(s, (2, 1), (0, 1), 4), 4) == mat(control(4, (-2, 1), 4=>X))
    @test linop2dense(s->cyapply!(s, (2, 1), (0, 1), 4), 4) == mat(control(4, (-2, 1), 4=>Y))
    @test linop2dense(s->czapply!(s, (2, 1), (0, 1), 4), 4) == mat(control(4, (-2, 1), 4=>Z))
    @test linop2dense(s->cxapply!(s, 2, 0, 1), 2) == mat(control(2, -2, 1=>X))
    @test linop2dense(s->cyapply!(s, 2, 0, 1), 2) == mat(control(2, -2, 1=>Y))
    @test linop2dense(s->czapply!(s, 2, 0, 1), 2) == mat(control(2, -2, 1=>Z))
end

@testset "U1apply!" begin
    ⊗ = kron
    Ds = randn(ComplexF64, 2, 2)
    Pm = pmrand(ComplexF64, 2)
    Dv = Diagonal(randn(ComplexF64, 2))
    II = mat(I2)
    v = randn(ComplexF64, 1<<4)
    @test u1apply!(copy(v), Ds, 3) ≈ (II ⊗ Ds ⊗ II ⊗ II)*v ≈ u1apply!(reshape(copy(v), :,1), Ds, 3)
    @test u1apply!(copy(v), Pm, 3) ≈ (II ⊗ Pm ⊗ II ⊗ II)*v ≈ u1apply!(reshape(copy(v), :,1), Pm, 3)
    @test u1apply!(copy(v), Dv, 3) ≈ (II ⊗ Dv ⊗ II ⊗ II)*v ≈ u1apply!(reshape(copy(v), :,1), Dv, 3)

end
