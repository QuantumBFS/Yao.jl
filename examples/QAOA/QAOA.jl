# required packages: NLopt, SCS and Convex
using Yao, BitBasis
using NLopt

include("maxcut_gw.jl")

HB(nbit::Int) = sum([put(nbit, i=>X) for i=1:nbit])
tb = TimeEvolution(HB(3) |> cache, 0.1; check_hermicity=false)
function HC(W::AbstractMatrix)
    nbit = size(W, 1)
    ab = Any[]
    for i=1:nbit,j=i+1:nbit
        if W[i,j] != 0
            push!(ab, 0.5*W[i,j]*repeat(nbit, Z, [i,j]))
        end
    end
    sum(ab)
end

function qaoa_circuit(W::AbstractMatrix, depth::Int; use_cache::Bool=false)
    nbit = size(W, 1)
    hb = HB(nbit)
    hc = HC(W)
	use_cache && (hb = hb |> cache; hc = hc |> cache)
    c = chain(nbit, [repeat(nbit, H, 1:nbit)])
    append!(c, [chain(nbit, [time_evolve(hc, 0.0, tol=1e-5, check_hermicity=false), time_evolve(hb, 0.0, tol=1e-5, check_hermicity=false)]) for i=1:depth])
end


function cobyla_optimize(circuit::AbstractBlock{N}, hc::AbstractBlock; niter::Int) where N
    function f(params, grad)
        reg = zero_state(N) |> dispatch!(circuit, params)
        loss = expect(hc, reg) |> real
        #println(loss)
        loss
    end
    opt = Opt(:LN_COBYLA, nparameters(circuit))
    min_objective!(opt, f)
    maxeval!(opt, niter)
    cost, params, info = optimize(opt, parameters(circuit))
    pl = zero_state(N) |> circuit |> probs
    cost, params, pl
end

using Random, Test
@testset "qaoa circuit" begin
	Random.seed!(2)
	nbit = 5
	W = [0 5 2 1 0;
		 5 0 3 2 0;
		 2 3 0 0 0;
		 1 2 0 0 4;
		 0 0 0 4 0]

	# the exact solution
	exact_cost, sets = goemansWilliamson(W)

	hc = HC(W)
	@test ishermitian(hc)
	# the actual loss is -<Hc> + sum(wij)/2
	@test -expect(hc, product_state(5, bmask(sets[1]...)))+sum(W)/4 ≈ exact_cost

	# build a QAOA circuit and start training.
	qc = qaoa_circuit(W, 20; use_cache=true)
	opt_pl = nothing
	opt_cost = Inf
	for i = 1:10
		dispatch!(qc, :random)
		cost, params, pl = cobyla_optimize(qc, hc; niter=2000)
		@show cost
		cost < opt_cost && (opt_pl = pl)
	end

	# check the correctness of result
	config = argmax(opt_pl)-1
	@test config in [bmask(set...) for set in sets]
end
