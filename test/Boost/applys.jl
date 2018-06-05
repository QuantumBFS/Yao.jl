using Compat.Test
using Yao
using Yao.Boost
using Yao.Blocks

# import Yao: xapply!, yapply!, zapply!, cxapply!, cyapply!, czapply!

apply2mat(applyfunc!::Function, num_bit::Int) = applyfunc!(eye(Complex128, 1<<num_bit))

# struct Register{N, T<:Complex}
#     state::Vector{T}
# end

@testset "xyz" begin
    @test apply2mat(s->xapply!(s, [1]), 1) == mat(X)
    @test apply2mat(s->yapply!(s, [1]), 1) == mat(Y)
    @test apply2mat(s->zapply!(s, [1]), 1) == mat(Z)

    @test apply2mat(s->cxapply!(s, 2, 1), 2) == mat(control(2, 2, 1=>X))
    @test apply2mat(s->cyapply!(s, 2, 1), 2) == mat(control(2, 2, 1=>Y))
    @test apply2mat(s->czapply!(s, 2, 1), 2) == mat(control(2, 2, 1=>Z))
end
