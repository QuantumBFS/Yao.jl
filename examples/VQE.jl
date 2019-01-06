using Yao, Yao.Blocks
using QuAlgorithmZoo
using KrylovKit

function ed_groundstate(h::MatrixBlock)
    E, V = eigsolve(h |> mat, 1, :SR, ishermitian=true)
    println("Ground State Energy is $(E[1])")
    register(V[1])
end

N = 5
c = random_diff_circuit(N, N, [i=>mod(i,N)+1 for i=1:N], mode=:Merged) |> autodiff(:QC)
dispatch!(c, :random)
hami = heisenberg(N)
ed_groundstate(hami)

vqe_solve(c, hami)
