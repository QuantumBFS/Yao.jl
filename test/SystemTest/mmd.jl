export Kernel, RBFKernel
"""
general interface of Kernel.
"""
abstract type Kernel end  # kernel matrix should have been put here

"""
RBF Kernel.
"""
struct RBFKernel <: Kernel
    sigma_list::Vector{Float64}
    kernel_matrix::Array{Float64,2}
end

########### Kernel Operations  ##################

export hilbert_rbf_kernel, rbf_kernel_matrix, kernel_expect
"""
get an RBF kernel instance from Hilbert basis.
"""
function hilbert_rbf_kernel(num_bit::Int, sigma_list::Vector{Float64}, is_binary::Bool)
    basis = collect(0:(1<<num_bit-1))
    return RBFKernel(sigma_list, rbf_kernel_matrix(basis, basis, sigma_list, is_binary))
end

"""
the expectation value of a kernel function.
"""
kernel_expect(kernel::Kernel, px::Vector{Float64}, py::Vector{Float64}) = px' * kernel.kernel_matrix * py

"""
RBF kernel function.
"""
IRvec = Union{Vector{Int}, Vector{Real}}
function rbf_kernel_matrix(x::IRvec, y::IRvec, sigma_list::Vector{Float64}, is_binary::Bool)
    if length(sigma_list) == 0
        throw(DimensionMismatch("At least 1 sigma parameters is required for RBM kernel!"))
    end

    # calculate distance
    if is_binary
        dx2 = map(count_ones, xor.(x, y'))
    else
        dx2 = (x .- y').^2
    end

    # calculate kernel matrix
    K = 0
    for sigma in sigma_list
        gamma = 1.0 / (2 * sigma)
        K = K + exp.(-gamma * dx2)
    end
    return K
end

######### MMD operations #########

export mmd_loss, mmd_witness
"""
MMD loss function.
"""
function mmd_loss(px::Vector{Float64}, kernel::Kernel, py::Vector{Float64})
    pxy = px-py
    return kernel_expect(kernel, pxy, pxy)
end

"""
witness function for kernel.
"""
function mmd_witness(kernel::Kernel, px::Vector{Float64}, py::Vector{Float64})
    return kernel.kernel_matrix * px - kernel.kernel_matrix * py
end

