include("Grover.jl")
using Test, BitBasis

"""traditional grover search algorithm."""
function grover_search(oracle::AbstractBlock{N}, gen::AbstractBlock{N}=repeat(N,H,1:N)) where N
    reg = zero_state(N) |> gen
    for i = 1:num_grover_step(oracle, gen)
        grover_step!(reg, oracle, gen)
    end
    return reg
end

function grover_circuit(oracle::AbstractBlock{N}, gen::AbstractBlock{N}, niter::Int=num_grover_step(oracle, gen)) where {N}
    chain(N, chain(oracle, reflect_circuit(gen)) for i = 1:niter)
end

#################### Tests ##################

@testset "oracle" begin
    oracle = inference_oracle(3, [2,-1,3])
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
    oracle = inference_oracle(num_bit, push!(collect(Int, 1:num_bit-1), num_bit))

    psi = grover_search(oracle)
    target_state = zeros(1<<num_bit); target_state[end] = 1
    @test isapprox(abs(statevec(psi)'*target_state), 1, atol=1e-3)
end

@testset "groverblock" begin
    gen = repeat(5, H, 1:5)
    or = inference_oracle(5, [-1,2,5,4,3])
    gb = grover_circuit(or, gen)
    @test apply!(zero_state(5) |> gen, gb) == grover_search(or)
end

@testset "test inference" begin
    Random.seed!(2)
    num_bit = 12
    gen = dispatch!(variational_circuit(num_bit), :random)
    psi0 = zero_state(num_bit) |> gen
    #psi0 = uniform_state(num_bit)
    evidense = [1, 2, 3, 4, 5, 6, 7, 8, 9]
    #evidense = collect(1:num_bit)

    # the desired subspace
    basis = collect(UInt, 0:1<<num_bit-1)
    subinds = [itercontrol(num_bit, abs.(evidense), Int.(evidense.>0))...]

    v_desired = statevec(psi0)[subinds .+ 1]
    p = norm(v_desired)^2
    v_desired[:] ./= sqrt(p)

    # search the subspace
    psi = grover_search(inference_oracle(num_bit, evidense), gen)
    @test isapprox((psi.state[subinds .+ 1]'*v_desired) |> abs2, 1, atol=3e-2)
end
