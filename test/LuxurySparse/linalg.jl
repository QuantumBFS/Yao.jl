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
                @test !issubtype(typeof(lres), StridedMatrix)
                @test !issubtype(typeof(rres), StridedMatrix)
            end
        end
    end
end

@testset "mul-vector" begin
    lres = v'*pm
    rres = pm*v
    flres = v' * Matrix(pm)
    frres = Matrix(pm) * v
    @test lres == flres
    @test rres == frres
    @test eltype(lres) == eltype(flres)
    @test eltype(rres) == eltype(frres)
end
