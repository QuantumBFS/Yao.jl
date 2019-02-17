using YaoArrayRegister
using Test

@testset "test utils" begin
    include("utils.jl")
end

@testset "test ArrayReg" begin
    include("register.jl")
end

@testset "test focus" begin
    include("focus.jl")
end
