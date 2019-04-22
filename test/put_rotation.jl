using YaoBlocks, YaoArrayRegister, BenchmarkTools, StaticArrays

r = rand_state(20)
U = @SMatrix rand(ComplexF64, 2, 2)

t1 = @benchmark instruct!($(statevec(r)), $U, 1)
t2 = @benchmark instruct!($(statevec(r)), $(Matrix(U)), 1)
(minimum(t1).time - minimum(t2).time) / minimum(t1).time

v = statevec(r)
mU = Matrix(U)

@profiler for i in 1:100
    instruct!(v, U, (1, ))
end

@profiler for i in 1:100
    instruct!(v, mU, (1, ))
end


function instruct2!(st, U, loc)
    a, c, b, d = U
    step = 1 << (loc - 1)
    step_2 = 1 << loc
    kernel(st, step, step_2, a, b, c, d)
end

@inline function kernel(state, step, step_2, a, b, c, d)
    for j in 0:step_2:size(state, 1)-step
        kernel2(state, U, step, step_2, a, b, c, d, j)
    end
    return state
end

@inline function kernel2(state, step, step_2, a, b, c, d, j)
    @inbounds for i in j+1:j+step
        YaoArrayRegister.u1rows!(state, i, i+step, a, b, c, d)
    end
    return state
end

@benchmark instruct2!($(r.state), $U, 1)

@benchmark instruct2!($(r.state), $(Matrix(U)), 1)

a, c, b, d = U
step = 1 << (1 - 1)
step_2 = 1 << 1

@benchmark kernel($(statevec(r)), $step, $step_2, $a, $b, $c, $d)

@benchmark a, c, b, d = $(Matrix(U))
