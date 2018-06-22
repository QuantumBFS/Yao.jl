using Yao
using BenchmarkTools

const NL = 10:3:25

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

function bench_xyz()
    bgate([repeat(G, [3]) for G in [X,Y,Z]], "xyz-report.dat")
end

function bench_cxyz()
    bgate([control((7,), 3=>G) for G in [X, Y, Z]], "cxyz-report.dat")
end

function bench_repeatxyz()
    bgate([repeat(G, collect(2:7)) for G in [X, Y, Z]], "repeatxyz-report.dat")
end

function bench_hgate()
   bgate([repeat(H, [3]), control((7,), 3=>H), repeat(H, collect(2:7))], "h-report.dat")
end

function bench_hgate()
    rollH(nbit) = roll(nbit, I2, fill(H, 6)..., fill(I2,nbit-7)...)
    bgate([repeat(H, [3]), control((7,), 3=>H), rollH], "h-report.dat")
end

function bench_rot()
    gates = [repeat(rot(G, 0.5), [3]) for G in [X, Y, Z]]
    bgate(gates, "rot-report.dat")
end

function bench_crot()
    gates = [control((7,), 3=>rot(G, 0.5)) for G in [X, Y, Z]]
    bgate(gates, "crot-report.dat")
end

function bench_toffoli()
    bgate([control((2,3), 5=>X)], "toffoli-report.dat")
end

function bench_all()
    bench_xyz()
    bench_cxyz()
    bench_repeatxyz()
    bench_hgate()
    bench_hgate()
    bench_rot()
    bench_crot()
    bench_toffoli()
end

#bench_all()
#bench_rot()
#bench_crot()
#bench_toffoli()
bench_hgate()
