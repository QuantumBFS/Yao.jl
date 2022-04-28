using Test, Yao
using Documenter

@testset "easybuld" begin
    include("easybuild/easybuild.jl")
end

Documenter.doctest(Yao.YaoAPI; manual=false)
Documenter.doctest(Yao.YaoArrayRegister; manual=false)
Documenter.doctest(Yao.YaoBlocks; manual=false)
Documenter.doctest(Yao.YaoSym; manual=false)
Documenter.doctest(Yao)