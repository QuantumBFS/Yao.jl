using YaoPlots, Test
using LinearAlgebra: normalize!, eigen
using Luxor: Drawing
using Yao

@testset "spherical coo" begin
    for i=1:10
        x = randn(3)
        @test collect(YaoPlots.polar_to_cartesian(YaoPlots.cartesian_to_polar(x...)...)) ≈ x
    end
end

@testset "state to polar" begin
    nx, ny, nz = normalize!(randn(3))
    sigma = nx * X + ny * Y + nz * Z
    m = Matrix(sigma)
    E, U = eigen(m)
    @test collect(YaoPlots.state_to_cartesian(U[:, 2])) ≈ [nx, ny, nz]
    @test collect(YaoPlots.state_to_cartesian(U[:, 1])) ≈ -[nx, ny, nz]

    reg = rand_state(1)
    @test collect(YaoPlots.state_to_cartesian(reg)) ≈ collect(YaoPlots.state_to_cartesian(density_matrix(reg)))
end

@testset "bloch" begin
    @test bloch_sphere("|ψ⟩"=>[2.2, 0.3im+0.3]; show_projection_lines=true,
        show_angle_texts=true, show_line=true, show01=true) isa Drawing
    # dark theme
    darktheme!()
    @test bloch_sphere("|ψ⟩"=>[2.2, 0.3im+0.3]; show_projection_lines=true,
        show_angle_texts=true, show_line=true, show01=true) isa Drawing
end

@testset "draw reg" begin
    @test bloch_sphere("|ψ⟩"=>rand_state(1)) isa Drawing
end

@testset "draw density matrix" begin
    rho = density_matrix(rand_state(2), 1)
    @test bloch_sphere("ρ"=>rho) isa Drawing
    bloch_sphere("|ψ⟩"=>rand_state(1), "ρ"=>density_matrix(rand_state(2), 1))
end