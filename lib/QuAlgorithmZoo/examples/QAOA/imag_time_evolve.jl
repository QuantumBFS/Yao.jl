"""imaginary time evolution solution to maximum cut problem."""
using Yao

@const_gate ZZ = mat(kron(Z,Z))

function maxcut_circuit(W::AbstractMatrix, τ)
    nbit = size(W, 1)
    ab = chain(nbit)
    for i=1:nbit,j=i+1:nbit
        if W[i,j] != 0
            #push!(ab, put(nbit, (i,j)=>0.5*W[i,j]*ZZ))
            push!(ab, put(nbit, (i,j)=>rot(ZZ, -im*W[i,j]*τ)))
        end
    end
	return ab
end

function maxcut_h(W::AbstractMatrix)
    nbit = size(W, 1)
    ab = Add{nbit}()
    for i=1:nbit,j=i+1:nbit
        if W[i,j] != 0
            #push!(ab, put(nbit, (i,j)=>0.5*W[i,j]*ZZ))
            push!(ab, put(nbit, (i,j)=>0.5*W[i,j]*ZZ))
        end
    end
	return ab
end

using Random, Test
@testset "iqaoa circuit" begin
	Random.seed!(2)
	nbit = 5
	# exact solution is [(1,3,4), (2,5)]
	W = [0 5 2 1 0;
		 5 0 3 2 0;
		 2 3 0 0 0;
		 1 2 0 0 4;
		 0 0 0 4 0]

	c = maxcut_circuit(W, 10)
	h = maxcut_h(W)
	reg = uniform_state(nbit) |> c

	# check the correctness of result
	opt_pl = reg |> probs
	config = argmax(opt_pl)-1
	@show BitStr64{nbit}(config), opt_pl[config+1]
	@test config == bit"01101" || config == bit"10010"
	@test isapprox(expect(h, reg |> normalize!), -5.5)
end
