using Yao
using QuAlgorithmZoo
using KrylovKit

function ed_groundstate(h::MatrixBlock)
    E, V = eigsolve(h |> mat, 1, :SR, ishermitian=true)
    println("Ground State Energy is $(E[1])")
    ArrayReg(V[1])
end

N = 5
c = random_diff_circuit(N, N, [i=>mod(i,N)+1 for i=1:N], mode=:Merged) |> autodiff(:QC)
dispatch!(c, :random)
hami = heisenberg(N)

# vqe ground state
vqe_solve!(c, hami)
