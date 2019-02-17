using YaoArrayRegister
using Test

@testset "test ArrayReg" begin
    include("register.jl")
end

@testset "test focus" begin
    include("focus.jl")
end
