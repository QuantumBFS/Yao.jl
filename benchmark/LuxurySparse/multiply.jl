using Compat
using BenchmarkTools
using Yao
using LuxurySparse

n=16
Id = IMatrix(1<<n)
V = randn(ComplexF64, 1<<n)
Dv = Diagonal(V)

Pm = pmrand(ComplexF64, 1<<n)
Sp = SparseMatrixCSC(Pm)

Ds = randn(ComplexF64, 1<<10,1<<10)

mats = [Id, Sp, Pm, Dv]
for A in mats
    bg = BenchmarkGroup()
    for B in mats
        if !(A===B===Ds)
            println("=================== $(typeof(A))-$(typeof(B)) ====================")
            display(@benchmark $A * $B)
            println()
        end
    end
    display(run(bg, verbose=true))
end
