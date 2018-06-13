using Compat
using Compat.Test

using Yao.Blocks
using Yao.LuxurySparse
import Yao.Blocks: swapapply!

linop2dense(applyfunc!::Function, num_bit::Int) = applyfunc!(Matrix{ComplexF64}(I, 1<<num_bit, 1<<num_bit))

@testset "matrix" begin
    @test mat(Swap{2, ComplexF64}(1, 2)) ≈ PermMatrix([1, 3, 2, 4], ones(1<<2))
end

@testset "apply" begin
    @test mat(Swap{4, ComplexF64}(1, 3)) ≈ linop2dense(s->swapapply!(s, 1,3), 4)
end
