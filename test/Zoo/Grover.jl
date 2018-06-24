using Yao
using Yao.Zoo
using Yao.Blocks
using Yao.Intrinsics
using Compat
using Compat.Test

function GroverSearch(oracle, num_bit::Int; psi::DefaultRegister = uniform_state(num_bit))
    it = GroverIter(oracle, psi)
    for (i, psi) in it end
    return (it.niter, psi)
end

function inference(psi::DefaultRegister, evidense::Vector{Int}, num_iter::Int)
    oracle = inference_oracle(evidense)(nqubits(psi))
    it = GroverIter(oracle, psi)
    for (i, psi) in it end
    it.niter, psi
end

@testset "oracle" begin
    oracle = inference_oracle([2,-1,3])(3)
    # ≈ method for Identity/PermuteMultiply/Sparse
    # add and mimus between sparse matrices.
    # alway use sorted CSC format.
    v = ones(1<<3)
    v[Int(0b110)+1] *= -1
    @test mat(oracle) ≈ Diagonal(v)
    @test mat(chain(phase(π), Z)) ≈ -mat(Z)
end

@testset "Grover Search" begin
    ####### Construct Grover Search Using Reflection Block
    num_bit = 12
    oracle = inference_oracle(push!(collect(Int, 1:num_bit-1), num_bit))(num_bit)

    niter, psi = GroverSearch(oracle, 12)
    target_state = zeros(1<<num_bit); target_state[end] = 1
    @test isapprox(abs(statevec(psi)'*target_state), 1, atol=1e-3)
end

@testset "test inference" begin
    num_bit = 12
    psi0 = rand_state(num_bit)
    #psi0 = uniform_state(num_bit)
    evidense = [1, 2, 3, 4, 5, 6, 7, 8, 9]
    #evidense = collect(1:num_bit)

    # the desired subspace
    basis = collect(UInt, 0:1<<num_bit-1)
    subinds = indices_with(num_bit, abs.(evidense), Int.(evidense.>0))

    v_desired = statevec(psi0)[subinds+1]
    p = norm(v_desired)^2
    v_desired[:] ./= sqrt(p)

    # search the subspace
    num_iter = num_grover_step(p)
    niter, psi = inference(psi0, evidense, num_iter)
    @test isapprox((psi.state[subinds+1]'*v_desired) |> abs2, 1, atol=1e-2)
end
