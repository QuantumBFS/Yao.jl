using Yao, Yao.Boost, Yao.Intrinsics, StaticArrays, Yao.Blocks
using CuYao, CUDA
using BenchmarkTools, Profile

nbit = 12
c = chain(put(nbit, 2=>X), put(nbit, 2=>rot(X, 0.2)), control(nbit, 3, 2=>rot(X,0.3)))
#c = chain(c..., c...,c...)
cc = c |> KernelCompiled
reg = rand_state(nbit) |> cu

@benchmark $reg |> copy |> $c[1] seconds = 2
@benchmark $reg |> copy |> $cc seconds = 2


reg = rand_state(9, 1000)
creg = reg |> cu
@benchmark focus!(reg |> copy, 1) do r
    measure!(r)
    r
end

@benchmark focus!(creg|>copy, 1) do r
    measure!(r)
    r
end

@benchmark focus!(creg, 1) do r
    measure_reset!(r)
    r
end

@profile for i=1:10 focus!(creg |> copy, 1) do r
    measure!(r)
    r
end
end

a = randn(1<<10)
ca = a |> cu

gpu_call(ca, (x->x^2, ca)) do state, f, ca
    ilin = linear_index(state)
    ca[ilin] = f(ca[ilin])
    return
end

gpu_call(1:1<<10, (x->x^2, ca)) do state, f, ca
    ilin = linear_index(state)
    ca[ilin] = f(ca[ilin])
    return
end


function xx_kernel(bits::Ints)
    ctrl = controller(bits[1], 0)
    mask = bmask(bits...)
    function kernel(state, inds)
        i = inds[1]
        b = i-1
        ctrl(b) && swaprows!(piecewise(state, inds), i, flip(b, mask) + 1)
    end
end

using CuYao: x_kernel, y_kernel, z_kernel
fx = x_kernel((3,4))
fy = y_kernel(3)
fz = z_kernel((3,4))

a = randn(1<<10)
ca = a |> cu
fs = (fx, fz)

@benchmark gpu_call(ca, (fs, ca)) do state, f, ca
    #ilin = linear_index(state)
    ilin = @cartesianidx ca
    for fi in fs
        fi(ca, ilin)
    end
    return
end

@device_code_warntype gpu_call(ca, ((fx, fz), ca)) do state, fs, ca
    ilin = @cartesianidx ca
    #for fi in fs fi(ca, ilin) end
    @Base.Cartesian.@nexprs $(length(fs)) i->fs[i](ca, ilin)
    #fs(ca, ilin)
    return
end

a ≈ Vector(ca)

@edit controller(3,0)
