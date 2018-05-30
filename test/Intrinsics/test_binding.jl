using Compat.Test
using Yao
import Yao.Intrinsics: SingleControlBlock, RepeatedBlock
import Yao.Const

xg = XGate{ComplexF64}()

@testset "Single Control" begin
    cb = SingleControlBlock{XGate, 2, ComplexF64}(xg, 2,1)
    @test mat(cb) == Const.Sparse.CNOT
end

@testset "Single Control" begin
    for G in [:X, :Y, :Z]
        MAT = Symbol(:(Const.Sparse.PAULI_), G)
        rb = RepeatedBlock{$(Symbol(G, :Gate)), 2, Complex128}(xg, [1,2])
        @test mat(rb) == kron($MAT, $MAT)
    end
end

@testset "Single Control" begin
    mcb = ControlBlock{XGate, 3, Complex128}(xg, [3, 2], 1)
    @test mat(mcb) == Const.Sparse.Toffoli
end
