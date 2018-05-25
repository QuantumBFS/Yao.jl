############################ Tests ##########################
using Compat.Test
include("identity.jl")
srand(2)

p1 = Identity(4)
sp = sprand(Complex128, 4,4, 0.5)
ds = rand(Complex128, 4,4)
pm = PermuteMultiply([2,3,4,1], randn(4))
v = [0.5, 0.3im, 0.2, 1.0]
dv = Diagonal(v)


@testset "kron" begin
    for source in [p1, sp, ds, dv, pm]
        for target in [p1, sp, ds, dv, pm]
            lres = kron(source, target)
            rres = kron(target, source)
            flres = kron(full(source), full(target))
            frres = kron(full(target), full(source))
            @test lres == flres
            @test rres == frres
            @test eltype(lres) == eltype(flres)
            @test eltype(rres) == eltype(frres)
            if !(target === ds && source === ds)
                @test !issubtype(typeof(lres), StridedMatrix)
                @test !issubtype(typeof(rres), StridedMatrix)
            end
        end
    end
end

@testset "multiply" begin
    for source in [p1, sp, ds, dv, pm]
        for target in [p1, sp, ds, dv, pm]
            lres = source * target
            rres = target * source
            flres = full(source) * full(target)
            frres = full(target) * full(source)
            @test allclose(lres, flres)
            @test allclose(rres, frres)
            @test eltype(lres) == eltype(flres)
            @test eltype(rres) == eltype(frres)
            if !(target === ds || source === ds)
                @test !issubtype(typeof(lres), StridedMatrix)
                @test !issubtype(typeof(rres), StridedMatrix)
            end
        end
    end
end

@testset "mul-vector" begin
    lres = v'*pm
    rres = pm*v
    flres = full(v') * full(pm)
    frres = full(pm) * full(v)
    @test lres == flres
    @test rres == frres
    @test eltype(lres) == eltype(flres)
    @test eltype(rres) == eltype(frres)
end

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
    for op in [conj, real, transpose, copy, inv]
        @test op(p1) == eye(4)
        @test typeof(op(p1)) == typeof(p1)
    end
    @test imag(p1) == zeros(4, 4)
    @test p1' == eye(4)
    @test typeof(p1') == typeof(p1)
end

@testset "elementary" begin
    @test all(isapprox.(conj(p1), conj(full(p1))))
    @test all(isapprox.(real(p1), real(full(p1))))
    @test all(isapprox.(imag(p1), imag(full(p1))))
end

@testset "basicmath" begin
    @test p1*2im == full(p1)*2im
    @test p1/2.0 == full(p1)/2.0
end

include("permmul.jl")
