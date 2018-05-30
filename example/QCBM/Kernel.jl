"""
    MMD Kernels
"""
module Kernels

export expect, RBFKernel, loss

abstract type AbstractKernel end

struct RBFKernel <: AbstractKernel
    sigmas::Vector{Float64}
    matrix::Matrix{Float64}
end

function RBFKernel(nqubits::Int, sigmas::Vector{Float64}, isbinary::Bool)
    basis = collect(0:(1<<nqubits - 1))
    return RBFKernel(sigmas, rbf_kernel_matrix(basis, basis, sigmas, isbinary))
end

expect(kernel::RBFKernel, px::Vector{Float64}, py::Vector{Float64}) = px' * kernel.matrix * py

# RBF Kernel

function rbf_kernel_matrix(x::Vector, y::Vector, sigmas::Vector{Float64}, isbinary::Bool)
    if length(sigmas) == 0
        throw(DimensionMismatch("At least 1 sigma prameters is required for RBM kernel!"))
    end

    if isbinary
        dx2 = map(count_ones, xor.(x, y'))
    else
        dx2 = (x .- y').^2
    end

    K = 0
    for sigma in sigmas
        gamma = 1.0 / (2 * sigma)
        K = K + exp.(-gamma * dx2)
    end
    return K
end

function loss(px::AbstractVecOrMat{Float64}, kernel::RBFKernel, py::AbstractVecOrMat{Float64})
    pxy = px - py
    return expect(kernel, pxy, pxy)
end

end