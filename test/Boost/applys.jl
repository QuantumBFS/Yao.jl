using Compat
using Compat.Test
using Yao
using Yao.Boost
using Yao.Blocks

# import Yao: xapply!, yapply!, zapply!, cxapply!, cyapply!, czapply!

# struct Register{N, T<:Complex}
#     state::Vector{T}
# end

@testset "xyz" begin
    @test linop2dense(s->xapply!(s, [1]), 1) == mat(X)
    @test linop2dense(s->yapply!(s, [1]), 1) == mat(Y)
    @test linop2dense(s->zapply!(s, [1]), 1) == mat(Z)

    @test linop2dense(s->cxapply!(s, 2, 1), 2) == mat(control(2, 2, 1=>X))
    @test linop2dense(s->cyapply!(s, 2, 1), 2) == mat(control(2, 2, 1=>Y))
    @test linop2dense(s->czapply!(s, 2, 1), 2) == mat(control(2, 2, 1=>Z))
end
