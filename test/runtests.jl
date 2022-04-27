using Test, Yao
using Documenter

@testset "easybuld" begin
    include("easybuild/easybuild.jl")
end

Documenter.doctest(Yao.YaoAPI)
Documenter.doctest(Yao.YaoArrayRegister)
Documenter.doctest(Yao.YaoBlocks)
Documenter.doctest(Yao.YaoSym)