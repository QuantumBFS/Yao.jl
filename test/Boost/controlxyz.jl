using Compat
using Compat.Test

using Yao.Blocks
using Yao.Boost

@testset "control" begin

@test cxgate(ComplexF64, 2, [2], [1], 1) == [1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0] == controlled_U1(2, Matrix(mat(X)), [2], [1], 1) 
@test cxgate(ComplexF64, 2, [2], [0], 1) == [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1] == controlled_U1(2, Matrix(mat(X)), [2], [0], 1) 
@test czgate(ComplexF64, 2, [1], [1], 2) == [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 -1] == controlled_U1(2, mat(Z), [2], [1], 1) 
@test general_controlled_gates(3, [mat(P1)], [3], [mat(Y)], [2]) == controlled_U1(3, mat(Y), [3], [1], 2) == cygate(ComplexF64, 3, [3], [1], 2)

end
