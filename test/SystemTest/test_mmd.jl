using Compat.Test
include("mmd.jl")

@testset "mmd" begin
    # the non-binary version
    kernel = hilbert_rbf_kernel(2, [0.3, 3.0], false)
    target = reshape([2.        , 1.03535733, 0.51468975, 0.22313047,
       1.03535733, 2.        , 1.03535733, 0.51468975,
       0.51468975, 1.03535733, 2.        , 1.03535733,
       0.22313047, 0.51468975, 1.03535733, 2.        ], (4, 4))
    @test isapprox(kernel.kernel_matrix, target, atol=1e-4)

    # the binary version
    kernel = hilbert_rbf_kernel(2, [0.3, 3.0], true)
    target = reshape([2.        , 1.03535733, 1.03535733, 0.7522053 ,
       1.03535733, 2.        , 0.7522053 , 1.03535733,
       1.03535733, 0.7522053 , 2.        , 1.03535733,
       0.7522053 , 1.03535733, 1.03535733, 2.      ], (4, 4))
    @test isapprox(kernel.kernel_matrix, target, atol=1e-4)

    # MMD loss
    px = [0.2, 0.1, 0.5, 0.2]
    py = [0.7, 0.1, 0., 0.2]
    loss = mmd_loss(px, kernel, py)
    @test isapprox(0.482321336135912, loss, atol=1e-7)
end
