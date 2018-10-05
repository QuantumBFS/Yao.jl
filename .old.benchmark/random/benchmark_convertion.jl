using BenchmarkTools

using Yao
using LuxurySparse

Id = IMatrix{1<<16}()
Pm = pmrand(ComplexF64, 1<<16)
Dv = Diagonal(randn(ComplexF64, 1<<16))

bench = BenchmarkGroup()
bg = bench["To Sparse"] = BenchmarkGroup()
bg["permmatrix"] = @benchmarkable SparseMatrixCSC(Pm)
bg["imatrix"] = @benchmarkable SparseMatrixCSC(Id)
bg["diagonal"] = @benchmarkable SparseMatrixCSC(Dv)

showall(run(bench, verbose=true))
