using Yao, CUDA, Test
using Yao.YaoToEinsum: uniformsize

@testset "Yao Extensions" begin
    n = 5
    c = EasyBuild.qft_circuit(n)
    net = cu(yao2einsum(c))
    m = reshape(net.code(net.tensors...; size_info=uniformsize(net.code, 2)), 1<<n, 1<<n)
    @test m isa CuArray
    @test Matrix(m) ≈ mat(c)
end
