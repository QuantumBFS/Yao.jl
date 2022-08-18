using Test, YaoBlocks

@testset "test constant gates" begin
    include("const_gate.jl")
end

@testset "test identity gates" begin
    include("identity_gate.jl")
end

@testset "test phase gate" begin
    include("phase_gate.jl")
end

@testset "test shift gate" begin
    include("shift_gate.jl")
end

@testset "test rotation gate" begin
    include("rotation_gate.jl")
end

@testset "test time evolution" begin
    include("time_evolution.jl")
end

@testset "test general matrix gate" begin
    include("general_matrix_gate.jl")
end

@testset "test measure" begin
    include("measure.jl")
end

@testset "reflect" begin
    include("reflect.jl")
end

@testset "projector" begin
    include("projector.jl")
end

# it does nothing
@test chsubblocks(X, Y) === X
@test X[bit"1", bit"0"] == 1
@test X[bit"1", bit"1"] == 0
