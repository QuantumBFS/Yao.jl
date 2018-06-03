using Compat.Test

using Yao
import Yao.LuxurySparse: Identity, PermMatrix

srand(2)

p1 = Identity{4}()
sp = sprand(Complex128, 4,4, 0.5)
ds = rand(Complex128, 4,4)
pm = PermMatrix([2,3,4,1], randn(4))
v = [0.5, 0.3im, 0.2, 1.0]
dv = Diagonal(v)

@testset "basic" begin
    println(p1)
    @test p1==copy(p1)
    @test eltype(p1) == Bool
    @test size(p1) == (4, 4)
    @test size(p1, 1) == size(p1, 2) == 4
    @test Matrix(p1) == [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1]
end

@testset "sparse" begin
    @test nnz(p1) == 4
    @test nonzeros(p1) == ones(4)
end

@testset "linalg" begin
    for op in [conj, real, transpose, copy, inv]
        @test op(p1) == eye(4)
        @test typeof(op(p1)) == typeof(p1)
    end
    @test imag(p1) == zeros(4, 4)
    @test p1' == eye(4)
    @test typeof(p1') == typeof(p1)
end

@testset "elementary" begin
    @test all(isapprox.(conj(p1), conj(Matrix(p1))))
    @test all(isapprox.(real(p1), real(Matrix(p1))))
    @test all(isapprox.(imag(p1), imag(Matrix(p1))))
end

@testset "basicmath" begin
    @test p1*2im == Matrix(p1)*2im
    @test p1/2.0 == Matrix(p1)/2.0
end
