export mat_back_jacobian, apply_back_jacobian, ng
export test_apply_back, test_mat_back

function ng(f, θ, δ = 1e-5)
    res = []
    for i in 1:length(θ)
        push!(res, (f(ireplace(θ, i => θ[i] + δ / 2)) - f(ireplace(θ, i => θ[i] - δ / 2))) / δ)
    end
    cat(res..., dims = 3)
end

ireplace(vec::Vector, pair::Pair) = (v = copy(vec); v[pair.first] = pair.second; v)
ireplace(vec::Number, pair::Pair) = pair.second

function mat_back_jacobian(T, block, θ; use_outeradj = false)
    dispatch!(block, θ)
    m = mat(T, block)
    N = size(m, 1)
    jac = zeros(T, size(m)..., length(θ))
    zm = use_outeradj ? OuterProduct(zeros(T, N), zeros(T, N)) : zero(m)
    for j in 1:size(m, 2)
        @inbounds for i in 1:size(m, 1)
            if m[i, j] != 0
                _setval(zm, i, j, 1)
                jac[i, j, :] = mat_back(ComplexF64, block, zm)
                _setval(zm, i, j, 1im)
                jac[i, j, :] += 1im * mat_back(ComplexF64, block, zm)
                _setval(zm, i, j, 0)
            end
        end
    end
    return jac
end
_setval(m::AbstractMatrix, i, j, v) = (m[i, j] = v; m)
_setval(m::OuterProduct, i, j, v) = (m.left[i] = v == 0 ? 0 : 1; m.right[j] = v; m)
Base.setindex!(m::PermMatrix, v, i, j) = m.perm[i] == j ? m.vals[i] = v : error()

function apply_back_jacobian(reg0::ArrayReg{B}, block, θ; kwargs...) where {B}
    dispatch!(block, θ)
    out = apply!(copy(reg0), block)
    m = out.state
    zm = zero(m)
    jac = zeros(eltype(m), size(m)..., length(θ))
    for j in 1:size(m, 2)
        @inbounds for i in 1:size(m, 1)
            if m[i, j] != 0
                zm[i, j] = 1
                (in, inδ), col = apply_back((copy(out), ArrayReg{B}(copy(zm))), block; kwargs...)
                @assert in ≈ reg0
                jac[i, j, :] = col
                zm[i, j] *= 1im
                (in, inδ), col = apply_back((copy(out), ArrayReg{B}(copy(zm))), block)
                jac[i, j, :] += 1im * col
                zm[i, j] = 0
            end
        end
    end
    return jac
end

function test_mat_back(
    T,
    block::AbstractBlock{N},
    param;
    δ = 1e-5,
    use_outeradj::Bool = false,
) where {N}
    function mfunc(param)
        dispatch!(block, param)
        mat(T, block)
    end
    # test loss is `real(sum(rand_matrix .* m))`
    got = mat_back_jacobian(T, block, param; use_outeradj = use_outeradj)
    num = ng(mfunc, param, δ)
    res = isapprox(got, num, atol = 10 * δ)
    if !res
        @show size(got)
        @show got
        @show num
    end
    return res
end

function test_apply_back(reg0, block::AbstractBlock{N}, param; δ = 1e-5, kwargs...) where {N}
    function mfunc(param)
        dispatch!(block, param)
        apply!(copy(reg0), block).state
    end
    # test loss is `real(sum(rand_matrix .* m))`
    got = apply_back_jacobian(reg0, block, param; kwargs...)
    num = ng(mfunc, param, δ)
    res = isapprox(got, num, atol = 10 * δ)
    if !res
        @show got
        @show num
    end
    return res
end
