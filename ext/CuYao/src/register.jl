cu(reg::ArrayReg{D}) where D = ArrayReg{D}(CuArray(reg.state))
cpu(reg::ArrayReg{D}) where D = ArrayReg{D}(Array(reg.state))
cu(reg::BatchedArrayReg{D}) where D = BatchedArrayReg{D}(CuArray(reg.state), reg.nbatch)
cpu(reg::BatchedArrayReg{D}) where D = BatchedArrayReg{D}(Array(reg.state), reg.nbatch)
cu(reg::DensityMatrix{D}) where D = DensityMatrix{D}(CuArray(reg.state))
cpu(reg::DensityMatrix{D}) where D = DensityMatrix{D}(Array(reg.state))
const AbstractCuArrayReg{D, T, MT} = AbstractArrayReg{D, T, MT} where MT<:DenseCuArray
const CuArrayReg{D, T, MT} = ArrayReg{D, T, MT} where MT<:DenseCuArray
const CuBatchedArrayReg{D, T, MT} = BatchedArrayReg{D, T, MT} where MT<:DenseCuArray
const CuDensityMatrix{D, T, MT} = DensityMatrix{D, T, MT} where MT<:DenseCuMatrix

function batch_normalize!(s::DenseCuArray, p::Real=2)
    p!=2 && throw(ArgumentError("p must be 2!"))
    s./=norm2(s, dims=1)
    return s
end

@inline function tri2ij(l::Int)
    i = ceil(Int, sqrt(2*l+0.25)-0.5)
    j = l-i*(i-1)÷2
    return i+1,j
end

############### MEASURE ##################
function measure(::ComputationalBasis, reg::ArrayReg{D, T, MT} where MT<:DenseCuArray, ::AllLocs; rng::AbstractRNG=Random.GLOBAL_RNG, nshots::Int=1) where {D,T}
    _measure(rng, basis(reg), reg |> probs |> Vector, nshots)
end

# TODO: optimize the batch dimension using parallel sampling
function measure(::ComputationalBasis, reg::BatchedArrayReg{D, T, MT} where MT<:DenseCuArray, ::AllLocs; rng::AbstractRNG=Random.GLOBAL_RNG, nshots::Int=1) where {D,T}
    regm = reg |> rank3
    pl = dropdims(mapreduce(abs2, +, regm, dims=2), dims=2)
    return _measure(rng, basis(reg), pl |> Matrix, nshots)
end

function measure!(::RemoveMeasured, ::ComputationalBasis, reg::AbstractCuArrayReg{D}, ::AllLocs; rng::AbstractRNG=Random.GLOBAL_RNG) where D
    regm = reg |> rank3
    B = size(regm, 3)
    nregm = similar(regm, D ^ nremain(reg), B)
    pl = dropdims(mapreduce(abs2, +, regm, dims=2), dims=2)
    pl_cpu = pl |> Matrix
    res_cpu = map(ib->_measure(rng, basis(reg), view(pl_cpu, :, ib), 1)[], 1:B)
    res = CuArray(res_cpu)
    CI = Base.CartesianIndices(nregm)
    @inline function kernel(ctx, nregm, regm, res, pl)
        state = @linearidx nregm
        @inbounds i,j = CI[state].I
        @inbounds r = Int(res[j])+1
        @inbounds nregm[i,j] = regm[r,i,j]/CUDA.sqrt(pl[r, j])
        return
    end
    gpu_call(kernel, nregm, regm, res, pl)
    reg.state = reshape(nregm,1,:)
    return reg isa ArrayReg ? Array(res)[] : res
end

function measure!(::NoPostProcess, ::ComputationalBasis, reg::AbstractCuArrayReg{D, T}, ::AllLocs; rng::AbstractRNG=Random.GLOBAL_RNG) where {D, T}
    regm = reg |> rank3
    B = size(regm, 3)
    pl = dropdims(mapreduce(abs2, +, regm, dims=2), dims=2)
    pl_cpu = pl |> Matrix
    res_cpu = map(ib->_measure(rng, basis(reg), view(pl_cpu, :, ib), 1)[], 1:B)
    res = CuArray(res_cpu)
    CI = Base.CartesianIndices(regm)

    @inline function kernel(ctx, regm, res, pl)
        state = @linearidx regm
        @inbounds k,i,j = CI[state].I
        @inbounds rind = Int(res[j]) + 1
        @inbounds regm[k,i,j] = k==rind ? regm[k,i,j]/CUDA.sqrt(pl[k, j]) : T(0)
        return
    end
    gpu_call(kernel, regm, res, pl)
    return reg isa ArrayReg ? Array(res)[] : res
end

function YaoArrayRegister.measure!(
    ::NoPostProcess,
    bb::BlockedBasis,
    reg::AbstractCuArrayReg{D,T},
    ::AllLocs;
    rng::AbstractRNG = Random.GLOBAL_RNG,
) where {D,T}
    state = @inbounds (reg|>rank3)[bb.perm, :, :]  # permute to make eigen values sorted
    B = size(state, 3)
    pl = dropdims(mapreduce(abs2, +, state, dims=2), dims=2)
    pl_cpu = pl |> Matrix
    pl_block = zeros(eltype(pl), nblocks(bb), B)
    @inbounds for ib = 1:B
        for i = 1:nblocks(bb)
            for k in subblock(bb, i)
                pl_block[i, ib] += pl_cpu[k, ib]
            end
        end
    end
    # perform measurements on CPU
    res_cpu = Vector{Int}(undef, B)
    @inbounds @views for ib = 1:B
        ires = sample(rng, 1:nblocks(bb), Weights(pl_block[:, ib]))
        # notice ires is `BitStr` type, can be use as indices directly.
        range = subblock(bb, ires)
        state[range, :, ib] ./= sqrt(pl_block[ires, ib])
        state[1:range.start-1, :, ib] .= zero(T)
        state[range.stop+1:size(state, 1), :, ib] .= zero(T)
        res_cpu[ib] = ires
    end
    # undo permute and assign back
    _state = reshape(state, 1 << nactive(reg), :)
    rstate = reshape(reg.state, 1 << nactive(reg), :)
    @inbounds rstate[bb.perm, :] .= _state
    return reg isa ArrayReg ? bb.values[res_cpu[]] : CuArray(bb.values[res_cpu])
end

function measure!(rst::ResetTo, ::ComputationalBasis, reg::AbstractCuArrayReg{D, T}, ::AllLocs; rng::AbstractRNG=Random.GLOBAL_RNG) where {D, T}
    regm = reg |> rank3
    B = size(regm, 3)
    pl = dropdims(mapreduce(abs2, +, regm, dims=2), dims=2)
    pl_cpu = pl |> Matrix
    res_cpu = map(ib->_measure(rng, basis(reg), view(pl_cpu, :, ib), 1)[], 1:B)
    res = CuArray(res_cpu)
    CI = Base.CartesianIndices(regm)

    @inline function kernel(ctx, regm, res, pl, val)
        state = @linearidx regm
        @inbounds k,i,j = CI[state].I
        @inbounds rind = Int(res[j]) + 1
        @inbounds k==val+1 && (regm[k,i,j] = regm[rind,i,j]/CUDA.sqrt(pl[rind, j]))
        CUDA.sync_threads()
        @inbounds k!=val+1 && (regm[k,i,j] = 0)
        return
    end

    gpu_call(kernel, regm, res, pl, rst.x)
    return reg isa ArrayReg ? Array(res)[] : res
end

function YaoArrayRegister.batched_kron(A::DenseCuArray{T1}, B::DenseCuArray{T2}) where {T1 ,T2}
    res = CUDA.zeros(promote_type(T1,T2), size(A,1)*size(B, 1), size(A,2)*size(B,2), size(A, 3))
    CI = Base.CartesianIndices(res)
    @inline function kernel(ctx, res, A, B)
        state = @linearidx res
        @inbounds i,j,b = CI[state].I
        i_A, i_B = divrem((i-1), size(B,1))
        j_A, j_B = divrem((j-1), size(B,2))
        @inbounds res[state] = A[i_A+1, j_A+1, b]*B[i_B+1, j_B+1, b]
        return
    end

    gpu_call(kernel, res, A, B)
    return res
end

"""
    YaoArrayRegister.batched_kron!(C::CuArray, A, B)

Performs batched Kronecker products in-place on the GPU.
The results are stored in 'C', overwriting the existing values of 'C'.
"""
function YaoArrayRegister.batched_kron!(C::CuArray{T3, 3}, A::DenseCuArray, B::DenseCuArray) where {T3}
    @boundscheck (size(C) == (size(A,1)*size(B,1), size(A,2)*size(B,2), size(A,3))) || throw(DimensionMismatch())
    @boundscheck (size(A,3) == size(B,3) == size(C,3)) || throw(DimensionMismatch())
    CI = Base.CartesianIndices(C)
    @inline function kernel(ctx, C, A, B)
        state = @linearidx C
        @inbounds i,j,b = CI[state].I
        i_A, i_B = divrem((i-1), size(B,1))
        j_A, j_B = divrem((j-1), size(B,2))
        @inbounds C[state] = A[i_A+1, j_A+1, b]*B[i_B+1, j_B+1, b]
        return
    end

    gpu_call(kernel, C, A, B)
    return C
end

function join(reg1::AbstractCuArrayReg{D}, reg2::AbstractCuArrayReg{D}) where {D}
    @assert nbatch(reg1) == nbatch(reg2)
    s1 = reg1 |> rank3
    s2 = reg2 |> rank3
    state = YaoArrayRegister.batched_kron(s1, s2)
    return arrayreg(copy(reshape(state, size(state, 1), :)); nlevel=D, nbatch=nbatch(reg1))
end

function Yao.insert_qudits!(reg::AbstractCuArrayReg{D}, loc::Int; nqudits::Int=1) where D
    na = nactive(reg)
    focus!(reg, 1:loc-1)
    reg2 = join(zero_state(nqudits; nbatch=nbatch(reg)) |> cu, reg) |> relax! |> focus!((1:na+nqudits)...)
    reg.state = reg2.state
    return reg
end

"""
    cuproduct_state([T=ComplexF64], total::Int, bit_config::Integer; nbatch=NoBatch())

The GPU version of [`product_state`](@ref).
"""
cuproduct_state(bit_str::BitStr; nbatch::Union{NoBatch,Int} = NoBatch()) =
    cuproduct_state(ComplexF64, bit_str; nbatch = nbatch)
cuproduct_state(bit_str::AbstractVector; nbatch::Union{NoBatch,Int} = NoBatch()) =
    cuproduct_state(ComplexF64, bit_str; nbatch = nbatch)
cuproduct_state(total::Int, bit_config::Integer; kwargs...) =
    cuproduct_state(ComplexF64, total, bit_config; kwargs...)
cuproduct_state(::Type{T}, bit_str::BitStr{N}; kwargs...) where {T,N} =
    cuproduct_state(T, N, buffer(bit_str); kwargs...)
cuproduct_state(::Type{T}, bit_configs::AbstractVector; kwargs...) where {T} =
    cuproduct_state(T, bit_literal(bit_configs...); kwargs...)
function cuproduct_state(
    ::Type{T},
    total::Int,
    bit_config::Integer;
    nbatch::Union{Int,NoBatch} = NoBatch(),
    nlevel::Int=2,
) where {T}
    raw = CUDA.zeros(T, nlevel ^ total, YaoArrayRegister._asint(nbatch))
    raw[Int(bit_config)+1,:] .= Ref(one(T))
    return arrayreg(raw; nbatch=nbatch, nlevel=nlevel)
end

cuzero_state(n::Int; kwargs...) = cuzero_state(ComplexF64, n; kwargs...)
cuzero_state(::Type{T}, n::Int; kwargs...) where {T} = cuproduct_state(T, n, 0; kwargs...)

"""
    curand_state([T=ComplexF64], n::Int; nbatch=1)

The GPU version of [`rand_state`](@ref).
"""
curand_state(n::Int; kwargs...) = curand_state(ComplexF64, n; kwargs...)

function curand_state(
    ::Type{T},
    n::Int;
    nbatch::Union{Int,NoBatch} = NoBatch(),
    nlevel = 2,
) where {T}
    raw = CUDA.randn(T, nlevel ^ n, YaoArrayRegister._asint(nbatch))
    return normalize!(arrayreg(raw; nbatch=nbatch, nlevel=nlevel))
end

"""
    cuuniform_state([T=ComplexF64], n::Int; nbatch=1)

The GPU version of [`uniform_state`](@ref).
"""
cuuniform_state(n::Int; kwargs...) = cuuniform_state(ComplexF64, n; kwargs...)
function cuuniform_state(::Type{T}, n::Int;
    nbatch::Union{Int,NoBatch} = NoBatch(),
    nlevel::Int = 2,
) where {T}
    raw = CUDA.ones(T, nlevel ^ n, YaoArrayRegister._asint(nbatch))
    return normalize!(arrayreg(raw; nbatch=nbatch, nlevel=nlevel))
end

"""
    cughz_state([T=ComplexF64], n::Int; nbatch=1)

The GPU version of [`ghz_state`](@ref).
"""
cughz_state(n::Int; kwargs...) = cughz_state(ComplexF64, n; kwargs...)
function cughz_state(::Type{T}, n::Int; kwargs...) where {T}
    reg = cuzero_state(T, n; kwargs...)
    reg.state[1:1,:] .= Ref(sqrt(T(0.5)))
    reg.state[end:end,:] .= Ref(sqrt(T(0.5)))
    return reg
end

#=
for FUNC in [:measure!, :measure!]
    @eval function $FUNC(rng::AbstractRNG, op::AbstractBlock, reg::AbstractCuArrayReg, al::AllLocs; kwargs...) where B
        E, V = eigen!(mat(op) |> Matrix)
        ei = Eigen(E|>cu, V|>cu)
        $FUNC(rng::AbstractRNG, ei, reg, al; kwargs...)
    end
end
=#

function YaoBlocks.expect(op::AbstractAdd, dm::CuDensityMatrix)
    sum(x->expect(x, dm), subblocks(op))
end
function YaoBlocks.expect(op::AbstractBlock, dm::CuDensityMatrix{D}) where D
    return tr(apply(ArrayReg{D}(dm.state), op).state)
end

measure(
    ::ComputationalBasis,
    reg::CuDensityMatrix,
    ::AllLocs;
    nshots::Int = 1,
    rng::AbstractRNG = Random.GLOBAL_RNG,
) = YaoArrayRegister._measure(rng, basis(reg), Array(reg |> probs), nshots)

