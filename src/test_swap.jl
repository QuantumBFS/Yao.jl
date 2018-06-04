using Yao
using Compat.Test

using Yao.Intrinsics
using Yao.LuxurySparse
import Yao.Intrinsics: basis

include("swap.jl")

############## MOVE to Basis Test
@testset "SwapBits" begin
    msk = bmask(2,5)
    @test swapbits2(7, msk) == 21
end
#####################

@testset "SwapGate" begin
    @test apply2mat(s->swapapply!(s, 1,3), 4) == swapgate(Float64, 4, 1, 3)
    @test swapgate(Complex128, 2, 1, 2) ≈ PermMatrix([1,3,2,4], ones(1<<2))
end
