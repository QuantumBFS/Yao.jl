using Compat
using Compat.Test
using Compat.LinearAlgebra

using Yao
import Yao.LuxurySparse: IMatrix, PermMatrix, notdense

Random.seed!(2)

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

    for m in [pm, sp, p1, dv]
        @test m |> notdense
        @test m' |> notdense
        @test transpose(m) |> notdense
    end
    for m in [ds, v]
        @test m |> notdense == false
        @test m' |> notdense == false
        @test transpose(m) |> notdense == false
    end
end

@testset "multiply" begin
    for source_ in [p1, sp, ds, dv, pm]
        for target in [p1, sp, ds, dv, pm]
            for source in [source_, source_', transpose(source_)]
                lres = source * target
                rres = target * source
                flres = Matrix(source) * Matrix(target)
                frres = Matrix(target) * Matrix(source)
                @test lres ≈ flres
                @test rres ≈ frres
                if !(target === p1 || parent(source) === p1)
                    @test eltype(lres) == eltype(flres)
                    @test eltype(rres) == eltype(frres)
                end
                if (target |> notdense) && (parent(source) |> notdense)
                    @test lres |> notdense
                    @test lres |> notdense
                end
            end
        end
    end
end

@testset "mul-vector" begin
    # permutation multiply
    lres = transpose(conj(v))*pm  #! v' not realized!
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
