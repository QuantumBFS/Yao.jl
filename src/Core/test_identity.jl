############################ Tests ##########################
using Compat.Test
include("identity.jl")
srand(2)

p1 = Identity(4)
p2 = sprand(Complex128, 4,4, 0.5)
p3 = rand(Complex128, 4,4)
v = [0.5, 0.3im, 0.2, 1.0]
Dv = Diagonal(v)

@testset "basic" begin
    println(p1)
    @test p1==copy(p1)
    @test eltype(p1) == Int
    @test size(p1) == (4, 4)
    @test size(p1, 1) == size(p1, 2) == 4
    @test full(p1) == [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1]
end

@testset "sparse" begin
    @test nnz(p1) == 4
    @test nonzeros(p1) == ones(4)
end

@testset "linalg" begin
    for op in [conj, real, imag, transpose, copy, inv]
        @test op(p1) == eye(4)
        @test typeof(op(p1)) == typeof(p1)
    end
    @test p1' == eye(4)
    @test typeof(p1') == typeof(p1)
end

@testset "mul" begin
    @test p2*p1 == full(p2)*p1

    for target in [p1, p2, p3, Dv]
        lres = p1*target
        rres = (target)*p1
        println(typeof(lres), typeof(rres))
        @test lres == target
        @test rres == target'
        println(typeof(target), typeof(lres), typeof(rres))
        @test typeof(lres) == typeof(target) == typeof(rres)
    end
end

@testset "elementary" begin
    @test all(isapprox.(conj(p1), conj(full(p1))))
    @test all(isapprox.(real(p1), real(full(p1))))
    @test all(isapprox.(imag(p1), imag(full(p1))))
end

@testset "basicmath" begin
    @test p1*2 == full(p1)*2
    @test p1/2 == full(p1)/2
end

@testset "kron" begin
    for target in [p1, p2, p3, Dv]
        lres = kron(p1, target)
        rres = kron(target, p1)
        @test lres == kron(full(p1), target)
        @test rres == kron(target, full(p1))
        @test typeof(lres) == typeof(target)
        @test typeof(rres) == typeof(target)
    end
end


