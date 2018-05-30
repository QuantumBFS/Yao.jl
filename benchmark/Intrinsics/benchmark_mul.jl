using BenchmarkTools

using Yao
using Yao: pmrand, II

n=16
Id = II(1<<n)
V = randn(Complex128, 1<<n)
Dv = Diagonal(V)

Pm = pmrand(Complex128, 1<<n)
Sp = sparse(Pm)

Ds = randn(Complex128, 1<<10,1<<10)

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
