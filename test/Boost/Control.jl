using Compat.Test
using Yao
using Yao.Intrinsics
using Yao.Blocks
using Yao.Boost

cb = ControlBlock{2}((2,), X, 1)
mat(cb)

@testset "Single Control" begin
    cb = ControlBlock{2}((2,), X, 1)
    @test mat(cb) == mat(CNOT)
end

@testset "Multiple Control" begin
    mcb = ControlBlock{3}((3, 2), X, 1)
    @test mat(mcb) ≈ mat(Toffoli)
end
