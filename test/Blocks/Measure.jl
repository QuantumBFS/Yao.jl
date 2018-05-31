using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

import Yao: rand_state, register, state

import Yao: _generate_sample_plan_from, _get_reduced_probability_distribution,
    direct_sample_step, direct_sample


@testset "test direct sampler" begin
    @info "NOTE: This sampler should be replaced by a QuMC.jl sampler"
    s = normalize!(rand(ComplexF64, 1<<10))
    p = abs2.(s)
    plan = _generate_sample_plan_from(p)
    @test plan[end] ≈ sum(p)
    @test plan[1] ≈ p[1]

    # a GHZ state
    state_array = zeros(ComplexF64, 1<<10)
    state_array[1] = 1/sqrt(2); state_array[end] = 1/sqrt(2);
    reg = register(state_array)
    p = _get_reduced_probability_distribution(reg, 4)
    @test p[1][1] ≈ 0.5
    @test p[1][end] ≈ 0.5
end

import Yao: measure!

@testset "measure!" begin

    # a GHZ state
    state_array = zeros(ComplexF64, 1<<4)
    state_array[1] = 1/sqrt(2); state_array[end] = 1/sqrt(2);
    reg = register(state_array)

    s, samples = measure!(reg, 1) # measure first qubit
    # we will get
    # |0000> or |1111>
    if samples[1] == 0
        @test state(s)[1] ≈ 1
    else
        @test state(s)[end] ≈ 1
    end
end
