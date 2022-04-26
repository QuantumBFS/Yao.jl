using Test, Yao
using Documenter

@testset "easybuld" begin
    include("easybuild/easybuild.jl")
end

Documenter.doctest(Yao.YaoAPI; fix=true)