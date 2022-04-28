using Test
using Yao
using YaoAPI
using YaoArrayRegister
using YaoBlocks
using YaoSym
using Documenter
using Random

@testset "easybuld" begin
    include("easybuild/easybuild.jl")
end

Documenter.doctest(YaoAPI; manual=false)
Documenter.doctest(YaoArrayRegister; manual=false)
Documenter.doctest(YaoBlocks; manual=false)
Documenter.doctest(YaoSym; manual=false)
# Documenter.doctest(Yao)
