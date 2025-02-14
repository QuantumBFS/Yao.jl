# TODO
# support norm(view(reshape(A, m, n), :, 1))
norm2(A::DenseCuArray; dims=1) = mapreduce(abs2, +, A, dims=dims) .|> CUDA.sqrt

function kron(A::DenseCuArray{T1}, B::DenseCuArray{T2}) where {T1, T2}
    res = CUDA.zeros(promote_type(T1,T2), (size(A).*size(B))...)
    @kernel function kernel(res, A, B)
        state = @index(Global, Linear)
        @inbounds inds = CartesianIndices(res)[state].I
        inds_A = (inds.-1) .÷ size(B) .+ 1
        inds_B = (inds.-1) .% size(B) .+ 1
        @inbounds res[state] = A[inds_A...]*B[inds_B...]
    end

    kernel(get_backend(res))(res, A, B; ndrange=size(res))
    res
end

"""
    kron!(C::CuArray, A, B)

Computes Kronecker products in-place on the GPU.
The results are stored in 'C', overwriting the existing values of 'C'.
"""
function Yao.YaoArrayRegister.kron!(C::CuArray{T3}, A::DenseCuArray{T1}, B::DenseCuArray{T2}) where {T1, T2, T3}
    @boundscheck (size(C) == (size(A,1)*size(B,1), size(A,2)*size(B,2))) || throw(DimensionMismatch())
    CI = Base.CartesianIndices(C)
    @kernel function kernel(C, A, B)
        state = @index(Global, Linear)
        @inbounds inds = CI[state].I
        inds_A = (inds.-1) .÷ size(B) .+ 1
        inds_B = (inds.-1) .% size(B) .+ 1
        @inbounds C[state] = A[inds_A...]*B[inds_B...]
    end

    kernel(get_backend(C))(C, A, B; ndrange=size(C))
    C
end

function getindex(A::DenseCuVector{T}, B::DenseCuArray{<:Integer}) where T
    res = CUDA.zeros(T, size(B)...)
    @kernel function kernel(res, A, B)
        state = @index(Global, Linear)
        @inbounds res[state] = A[B[state]]
    end
    kernel(get_backend(res))(res, A, B; ndrange=size(res))
    res
end

function getindex(A::AbstractVector, B::DenseCuArray{<:Integer})
    A[Array(B)]
end

YaoBlocks.AD.as_scalar(x::DenseCuArray) = Array(x)[]

# patch for ExponentialUtilities
YaoBlocks.compatible_multiplicative_operand(::CuArray, source::AbstractArray) = CuArray(source)
YaoBlocks.compatible_multiplicative_operand(::CuArray, source::CuArray) = source
