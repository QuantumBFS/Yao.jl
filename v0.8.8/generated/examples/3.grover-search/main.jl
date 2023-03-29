using Yao
using Yao.EasyBuild: variational_circuit
using LinearAlgebra

function grover_step!(reg::AbstractRegister, oracle, U::AbstractBlock)
    apply!(reg |> oracle, reflect_circuit(U))
end

function reflect_circuit(gen::AbstractBlock)
    N = nqubits(gen)
    reflect0 = control(N, -collect(1:N-1), N=>-Z)
    chain(gen', reflect0, gen)
end

function solution_state(oracle, gen::AbstractBlock)
    N = nqubits(gen)
    reg= zero_state(N) |> gen
    reg.state[real.(statevec(ArrayReg(ones(ComplexF64, 1<<N)) |> oracle)) .> 0] .= 0
    normalize!(reg)
end

function num_grover_step(oracle, gen::AbstractBlock)
    N = nqubits(gen)
    reg = zero_state(N) |> gen
    ratio = abs2(solution_state(oracle, gen)'*reg)
    Int(round(pi/4/sqrt(ratio)))-1
end

num_bit = 12
oracle = matblock(Diagonal((v = ones(ComplexF64, 1<<num_bit); v[Int(bit"000001100100")+1]*=-1; v)))

gen = repeat(num_bit, H, 1:num_bit)
reg = zero_state(num_bit) |> gen

target_state = solution_state(oracle, gen)

for i = 1:num_grover_step(oracle, gen)
    grover_step!(reg, oracle, gen)
    overlap = abs(reg'*target_state)
    println("step $(i-1), overlap = $overlap")
end

function single_try(oracle, gen::AbstractBlock, nstep::Int; nbatch::Int)
    N = nqubits(gen)
    reg = zero_state(N+1; nbatch)
    focus(reg, (1:N...,)) do r
        r |> gen
        for i = 1:nstep
            grover_step!(r, oracle, gen)
        end
        return r
    end
    reg |> checker
    res = measure!(RemoveMeasured(), reg, (N+1))
    return res, reg
end

ctrl = -collect(1:num_bit); ctrl[[3,6,7]] *= -1
checker = control(num_bit+1,ctrl, num_bit+1=>X)

maxtry = 100
nshot = 3

for nstep = 0:maxtry
    println("number of iter = $nstep")
    res, regi = single_try(oracle, gen, nstep; nbatch=3)

    # success!
    if any(==(1), res)
        overlap_final = viewbatch(regi, findfirst(==(1), res))'*target_state
        println("success, overlap = $(overlap_final)")
        break
    end
end

evidense = [1, 3, -4, 5, -6, 8, 9, 11, 12]
function inference_oracle(nbit::Int, locs::Vector{Int})
    control(nbit, locs[1:end-1], abs(locs[end]) => (locs[end]>0 ? Z : -Z))
end
oracle = inference_oracle(nqubits(reg), evidense)

gen = dispatch!(variational_circuit(num_bit), :random)
reg = zero_state(num_bit) |> gen

solution = solution_state(oracle, gen)
for i = 1:num_grover_step(oracle, gen)
    grover_step!(reg, oracle, gen)
    println("step $(i-1), overlap = $(abs(reg'*solution))")
end

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

