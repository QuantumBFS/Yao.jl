push!(LOAD_PATH, "/home/leo/jcode")
using Yao
using BenchmarkTools
using Yao.Blocks

import Base: |>
with!(reg) = reg
with(reg) = copy(reg)
|>(reg::AbstractRegister, blk::AbstractBlock) = apply!(reg, blk)

res_list = zeros(6, 6)
for (ib, nbit) in enumerate(10:3:25)
    reg = rand_state(nbit)
    for (ig, G) in enumerate([X, Y, Z])
        # single gate
        g3 = repeat(nbit, G, [3])
        res = @benchmark $reg |> $g3
        res_list[ib, 2*ig-1] = median(res).time
        c7g3 = control(nbit, (7,), 3=>G)
        res = @benchmark $reg |> $c7g3
        res_list[ib, 2*ig] = median(res).time
    end
end
println(res_list)
writedlm("xyzcyxz.dat", res_list)
