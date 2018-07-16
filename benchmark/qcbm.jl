using Yao, BenchmarkTools

c = chain(9, repeat(9, cache(chain(Rz(0.0), Rx(0.0), Rz(0.0))), (i,)) for i in 1:9)
rc = rollrepeat(9, chain(Rz(0.0), Rx(0.0), Rz(0.0)))
pc = chain(n, put(i=>cache(chain(Rz(0.0), Rx(0.0), Rz(0.0)))) for i in 1:n)
r = zero_state(9)

dispatch!(c, rand(nparameters(c)))

@benchmark apply!($r, $c)
@benchmark apply!($r, $rc)
@benchmark apply!($r, $pc)

m = mat(c)
st = statevec(r)

baseline = @benchmark $m * $st


@benchmark apply!($r, $(cache(c)))
