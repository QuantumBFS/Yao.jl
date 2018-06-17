#!/usr/bin/env julia7
push!(LOAD_PATH, "/home/leo/jcode")
using Yao
using BenchmarkTools
using Fire

with!(reg) = reg
with(reg) = copy(reg)
import Yao: |>
#|>(reg::AbstractRegister, blk::Function) = apply!(reg, blk(nqubits(reg)))

NL = 10:3:25

function bgate(ops, filename)
    println("Benchmarking $filename ...")
    res_list = zeros(6, ops |> length)
    for (ib, nbit) in enumerate(NL)
        reg = rand_state(nbit)
        for (ig, G) in enumerate(ops)
            println(G(nbit))
            res = @benchmark $reg |> $(G(nbit))
            res_list[ib, ig] = median(res).time
        end
    end
    println(res_list)
    writedlm(filename, res_list/1e3)
end

@main function xyz()
    bgate([repeat(G, [3]) for G in [X,Y,Z]], "xyz-report.dat")
end

@main function cxyz()
    bgate([control((7,), 3=>G) for G in [X, Y, Z]], "cxyz-report.dat")
end

@main function repeatxyz()
    bgate([repeat(G, collect(2:7)) for G in [X, Y, Z]], "repeatxyz-report.dat")
end

#@main function hgate()
#    bgate([repeat(H, [3]), control((7,), 3=>H), repeat(H, collect(2:7))], "h-report.dat")
#end
@main function hgate()
    rollH(nbit) = roll(nbit, I2, fill(H, 6)..., fill(I2,nbit-7)...)
    bgate([kron(3=>H), control((7,), 3=>H), rollH], "h-report.dat")
end

@main function rot()
    println(rot(X, 0.5))
    gates = [kron(3=>rot(G, 0.5)) for G in [X, Y, Z]]
    bgate(gates, "rot-report.dat")
end

@main function crot()
    gates = [control((7,), 3=>rot(G, 0.5)) for G in [X, Y, Z]]
    bgate(gates, "crot-report.dat")
end

@main function toffoli()
    bgate([control((2,3), 5=>X)], "toffoli-report.dat")
end
