using YaoArrayRegister
using Test

@testset "test utils" begin
    include("utils.jl")
    include("error.jl")
end

@testset "test ArrayReg" begin
    include("register.jl")
    include("operations.jl")
    include("focus.jl")
end

@testset "test instructions" begin
    include("instruct.jl")
end

@testset "test qudit instructions" begin
    include("qudit_instruct.jl")
end

@testset "test measure" begin
    include("measure.jl")
end

@testset "test density matrix" begin
    include("density_matrix.jl")
end
