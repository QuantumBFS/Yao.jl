using Yao, CUDA
using Yao.YaoToEinsum: uniformsize

@testset "Yao Extensions" begin
    n = 5
    c = EasyBuild.qft_circuit(n)
    optcode, xs = yao2einsum(c)
    @test Matrix(reshape(optcode(xs...; size_info=uniformsize(optcode, 2)), 1<<n, 1<<n)) ≈ mat(c)
end
