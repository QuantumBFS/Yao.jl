using Compat
using Compat.Test
using Compat.Random

using Yao
import Yao.LuxurySparse: IMatrix, PermMatrix

Random.seed!(2)

p1 = IMatrix{4}()
sp = sprand(ComplexF64, 4,4, 0.5)
ds = rand(ComplexF64, 4,4)
pm = PermMatrix([2,3,4,1], randn(4))
v = [0.5, 0.3im, 0.2, 1.0]
dv = Diagonal(v)


@testset "kron" begin
    for source in [p1, sp, ds, dv, pm]
        for target in [p1, sp, ds, dv, pm]
            lres = kron(source, target)
            rres = kron(target, source)
            flres = kron(Matrix(source), Matrix(target))
            frres = kron(Matrix(target), Matrix(source))
            @test lres == flres
            @test rres == frres
            @test eltype(lres) == eltype(flres)
            @test eltype(rres) == eltype(frres)
            if !(target === ds && source === ds)
                @test !(typeof(lres) <: StridedMatrix)
                @test !(typeof(rres) <: StridedMatrix)
            end
        end
    end
end
