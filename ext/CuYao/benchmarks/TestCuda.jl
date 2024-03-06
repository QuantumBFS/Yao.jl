using CUDA
using LinearAlgebra
using BenchmarkTools

function ms!(X::CuArray, s::Number)
    function kernel(X, s)
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        @inbounds X[i] *= s
        return
    end
    @cuda blocks=length(X) kernel(X, s)
    X
end

function ms1!(X::CuArray, a, b, c)
    k = f(a)
    function kernel(X, a, b, c)
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        k(X, i)
        k(X, i)
        k(X, i)
        #@inbounds X[i] *= a
        #@inbounds X[i] *= b
        #@inbounds X[i] *= c
        return
    end
    @cuda blocks=length(X)÷256 threads=256 kernel(X, a, b, c)
    X
end

@inline function f(s)
    @inline function kernel(X, i)
        X[i]*=s
    end
end
function ms2!(X::CuArray, s::Number)
    function kernel(X, s)
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        @inbounds X[i] *= s
        return
    end
    @cuda blocks=length(X)÷256 threads=256 kernel(X, s)
    X
end

a = randn(1<<10)
cua = cu(a)
@benchmark ms1!($cua, 1.001, 1.001, 1.001)
@benchmark ms2!(ms2!(ms2!($cua, 1.001), 1.001), 1.001)
bss = 1:length(cua)
@benchmark f(1.001).(cua, bss)

@benchmark rmul!($a, 1.01)
@benchmark ms!($cua, 1.0)
