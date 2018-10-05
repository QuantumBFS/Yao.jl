using BenchmarkTools
using LuxurySparse

id = IMatrix(1<<8)
v = randn(1<<8) + im*randn(1<<8)
Dv = Diagonal(v)

#sp = sprand(ComplexF64, 1<<8, 1<<8, 0.03)
#pm = PermuteMultiply(randperm(1<<8), randn(1<<8))
sp = SparseMatrixCSC(Dv)
ds = rand(ComplexF64, 1<<4,1<<4)
pm = PermMatrix(Dv)

mats = [id, sp, ds, pm, Dv]
for A in mats
    bg = BenchmarkGroup()
    for B in mats
        if !(A===B===ds)
            println("=================== $(typeof(A))-$(typeof(B)) ====================")
            display(@benchmark kron($A, $B))
            println()
        end
    end
    display(run(bg, verbose=true))
end
