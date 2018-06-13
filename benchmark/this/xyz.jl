push!(LOAD_PATH, "/home/leo/jcode")
using Yao
using BenchmarkTools
using Yao.Blocks

import Base: |>
with!(reg) = reg
with(reg) = copy(reg)
|>(reg::AbstractRegister, blk::AbstractBlock) = apply!(reg, blk)

nbit = 16
res_list = Float64[]
reg = rand_state(16)
for G in [X, Y, Z]
    # single gate
    g3 = repeat(nbit, G, [3])
    res = @benchmark $reg |> $g3
    push!(res_list, median(res).time)
    c7g3 = control(nbit, (7,), 3=>G)
    res = @benchmark $reg |> $c7g3
    push!(res_list, median(res).time)
end
println(res_list)
