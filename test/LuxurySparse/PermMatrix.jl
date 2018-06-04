using Compat
using Compat.Test
using Compat.Random
using Yao
import Yao.LuxurySparse: PermMatrix, pmrand

srand(2)
p1 = PermMatrix([1,4,2,3],[0.1, 0.2, 0.4im, 0.5])
p2 = PermMatrix([2,1,4,3],[0.1, 0.2, 0.4, 0.5])
#p3 = PermMatrix([4,1,2,3],[0.5, 0.4im, 0.3, 0.2])
p3 = pmrand(4)
sp = sprand(4, 4, 0.3)
v = [0.5, 0.3im, 0.2, 1.0]

@testset "basic" begin
    @test p1==copy(p1)
    @test eltype(p1) == ComplexF64
    @test eltype(p2) == Float64
    @test eltype(p3) == Float64
    @test size(p1) == (4, 4)
    @test size(p3) == (4, 4)
    @test size(p1, 1) == size(p1, 2) == 4
    @test Matrix(p1) == [0.1 0 0 0; 0 0 0 0.2; 0 0.4im 0 0; 0 0 0.5 0]
end

@testset "sparse" begin
    @test nnz(p1) == 4
    @test nonzeros(p1) == p1.vals
    @test dropzeros!(p1) == p1
end

@testset "linalg" begin
    @test inv(p1) * p1 ≈ Matrix(I, 4, 4)
    @test p1*transpose(p1) == diagm(0=>p1.vals.^2)
    #@test p1*adjoint(p1) == diagm(0=>abs.(p1.vals).^2)
    #@test all(isapprox.(adjoint(p3), transpose(conj(Matrix(p3)))))
    @test p1*p1' == diagm(0=>abs.(p1.vals).^2)
    @test all(isapprox.(p3', transpose(conj(Matrix(p3)))))
end

@testset "mul" begin
    @test p3*p2 == sparse(p3)*p2 == Matrix(p3)*p2

    # Multiply vector
    @test p3*v == Matrix(p3)*v
    @test v'*p3 == v'*Matrix(p3)
    @test p3*collect(1:4) == p3.perm.*p3.vals

    # Diagonal matrices
    Dv = Diagonal(v)
    @test p3*Dv == Matrix(p3)*Dv
    @test Dv*p3 == Dv*Matrix(p3)
end

@testset "elementary" begin
    @test all(isapprox.(conj(p1), conj(Matrix(p1))))
    @test all(isapprox.(real(p1), real(Matrix(p1))))
    @test all(isapprox.(imag(p1), imag(Matrix(p1))))
end

@testset "basicmath" begin
    @test p1*2 == Matrix(p1)*2
    @test p1/2 == Matrix(p1)/2
end

@testset "memorysafe" begin
    @test p1 == PermMatrix([1,4,2,3],[0.1, 0.2, 0.4im, 0.5])
    @test p2 == PermMatrix([2,1,4,3],[0.1, 0.2, 0.4, 0.5])
    @test v == [0.5, 0.3im, 0.2, 1.0]
end
