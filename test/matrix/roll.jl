using YaoBlockTree, YaoArrayRegister, BenchmarkTools

g = rollrepeat(20, chain(map(x->x(rand()), [Rx, Ry, Rz])))
st = rand_state(20)

@profiler for k in 1:20
    apply!(st, g)
end
