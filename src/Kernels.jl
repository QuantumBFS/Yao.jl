export AbstractKernel, RBFKernel, kmat, rbf_kernel, kernel_expect

abstract type AbstractKernel end

"""
    RBFKernel(σ, matrix)

RBF Kernel with dense array as kernel matrix.
"""
struct RBFKernel <: AbstractKernel
    sigma::Float64
    matrix::Matrix{Float64}
end

"""
    kmat(k::AbstractKernel) -> Matrix

Returns Kernel Matrix.
"""
function kmat end
kmat(mbf::RBFKernel) = mbf.matrix

"""
    rbf_kernel(basis, σ::Real) -> RBFKernel

Returns RBF Kernel Matrix.
"""
function rbf_kernel(basis, σ::Real)
    dx2 = (basis .- basis').^2
    RBFKernel(σ, exp.(-1/2σ * dx2))
end

"""
    kernel_expect(kernel::AbstractKernel, px::Vector{Float64}, py::Vector{Float64}) -> Float64

Returns the expectation value of kernel on specific distributions.
"""
kernel_expect(kernel::AbstractKernel, px::Vector, py::Vector=px) = px' * kmat(kernel) * py
