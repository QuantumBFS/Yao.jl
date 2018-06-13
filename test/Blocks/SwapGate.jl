using Compat
using Compat.Test

using Yao.Blocks
using Yao.LuxurySparse
using Yao.Intrinsics
import Yao.Blocks: swapapply!

@testset "matrix" begin
    @test mat(Swap{2, ComplexF64}(1, 2)) ≈ PermMatrix([1, 3, 2, 4], ones(1<<2))
end

@testset "apply" begin
    @test mat(Swap{4, ComplexF64}(1, 3)) ≈ linop2dense(s->swapapply!(s, 1,3), 4)
end
