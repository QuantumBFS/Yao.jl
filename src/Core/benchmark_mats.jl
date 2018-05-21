using BenchmarkTools
include("identity.jl")

id = II(1<<8)
v = randn(1<<8) + im*randn(1<<8)
Dv = Diagonal(v)

#sp = sprand(Complex128, 1<<8, 1<<8, 0.03)
#pm = PermuteMultiply(randperm(1<<8), randn(1<<8))
sp = sparse(Dv)
ds = rand(Complex128, 1<<4,1<<4)
pm = PermuteMultiply(Dv)

mats = [id, sp, ds, pm, Dv]
for A in mats
    bg = BenchmarkGroup()
    for B in mats
        if !(A===B===ds)
            #bg["$(typeof(A))-$(typeof(B))"] = @benchmarkable kron($A, $B)
            println("=================== $(typeof(A))-$(typeof(B)) ====================")
            display(@benchmark kron($A, $B))
            println()
        end
    end
    display(run(bg, verbose=true))
end

# TODO
# 1. I - PM
# 2. A - I/PM/D
