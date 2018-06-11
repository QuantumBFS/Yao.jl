using Compat
using Compat.Test

using Yao
import Yao.LuxurySparse: IMatrix, PermMatrix, swaprows, mulrow

srand(2)

p1 = IMatrix{4}()
sp = sprand(ComplexF64, 4,4, 0.5)
ds = rand(ComplexF64, 4,4)
pm = PermMatrix([2,3,4,1], randn(4))
v = [0.5, 0.3im, 0.2, 1.0]
dv = Diagonal(v)

@testset "invdet" begin
    ####### linear algebra  ######
    @test inv(p1) == inv(Matrix(p1))
    @test det(p1) == det(Matrix(p1))
    @test diag(p1) == diag(Matrix(p1))
    @test logdet(p1) == 0
    @test inv(pm) == inv(Matrix(pm))
end

@testset "multiply" begin
    for source in [p1, sp, ds, dv, pm]
        for target in [p1, sp, ds, dv, pm]
            lres = source * target
            rres = target * source
            flres = Matrix(source) * Matrix(target)
            frres = Matrix(target) * Matrix(source)
            @test lres ≈ flres
            @test rres ≈ frres
            if !(target === p1 || source === p1)
                @test eltype(lres) == eltype(flres)
                @test eltype(rres) == eltype(frres)
            end
            if !(target === ds || source === ds)
                @test !(typeof(lres) <: StridedMatrix)
                @test !(typeof(rres) <: StridedMatrix)
            end
        end
    end
end

@testset "mul-vector" begin
    # permutation multiply
    lres = RowVector(conj(v))*pm  #! v' not realized!
    rres = pm*v
    flres = v' * Matrix(pm)
    frres = Matrix(pm) * v
    @test lres == flres
    @test rres == frres
    @test eltype(lres) == eltype(flres)
    @test eltype(rres) == eltype(frres)

    # IMatrix
    @test v'*p1 == v'
    @test p1*v == v
end

@testset "swaprows & mulrow" begin
    a = [1,2,3,5.0]
    A = Float64.(reshape(1:8, 4,2))
    @test swaprows(copy(a), 2, 4) ≈ [1,5,3,2]
    @test swaprows(copy(a), 2, 4, 0.1, 0.2) ≈ [1,1,3,0.2]
    @test swaprows(copy(A), 2, 4) ≈ [1 5; 4 8; 3 7; 2 6]
    @test swaprows(copy(A), 2, 4, 0.1, 0.2) ≈ [1 5; 0.8 1.6; 3 7; 0.2 0.6]

    @test mulrow(copy(a), 2, 0.1) ≈ [1,0.2,3,5]
    @test mulrow(copy(A), 2, 0.1) ≈ [1 5; 0.2 0.6; 3 7; 4 8]
end
