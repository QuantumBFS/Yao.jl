#!/usr/bin/env julia7
push!(LOAD_PATH, "/home/leo/jcode")
using Yao
using BenchmarkTools
using Yao.Blocks
using Fire

with!(reg) = reg
with(reg) = copy(reg)
import Yao: |>
|>(reg::AbstractRegister, blk::Function) = apply!(reg, blk(nqubits(reg)))

NL = 10:3:25

function bgate(ops, filename)
    println("Benchmarking $filename ...")
    res_list = zeros(6, ops |> length)
    for (ib, nbit) in enumerate(NL)
        println("N = $nbit")
        reg = rand_state(nbit)
        for (ig, G) in enumerate(ops)
            res = @benchmark $reg |> $G
            res_list[ib, ig] = median(res).time
        end
    end
    println(res_list)
    writedlm(filename, res_list/1e3)
end

@main function xyz()
    bgate([repeat(G, (3,)) for G in [X,Y,Z]], "xyz-report.dat")
end

@main function cxyz()
    bgate([control((7,), 3=>G) for G in [X, Y, Z]], "cxyz-report.dat")
end

@main function repeatxyz(self)
    bgate([rot(X), rot(Y), rot(Z)], "repeatxyz-report.dat")
end

@main function hgate(self)
    bgate((ops.H), bCG(ops.H), bRG(ops.H), "h-report.dat")
end

@main function rot(self)
    gates = [bRot(ops.Rx), bRot(ops.Ry), bRot(ops.Rz), bCRot(ops.Rx), bCRot(ops.Ry), bCRot(ops.Rz)]
    bgate(gates, "rot-report.dat")
end

@main function toffoli(self)
    bgate([bToffoli()], "toffoli-report.dat")
end
