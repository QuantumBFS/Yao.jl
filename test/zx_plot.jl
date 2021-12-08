using Test
using ZXCalculus, YaoPlots
using YaoHIR, YaoLocations
using CompilerPluginTools

c = YaoHIR.Chain()
push_gate!(c, Val{:Sdag}(), 1)
push_gate!(c, Val{:H}(), 1)
push_gate!(c, Val{:S}(), 1)
push_gate!(c, Val{:S}(), 2)
push_gate!(c, Val{:H}(), 4)
push_gate!(c, Val{:CNOT}(), 3, 2)
push_gate!(c, Val{:CZ}(), 4, 1)
push_gate!(c, Val{:H}(), 2)
push_gate!(c, Val{:T}(), 2)
push_gate!(c, Val{:CNOT}(), 3, 2)
push_gate!(c, Val{:Tdag}(), 2)
push_gate!(c, Val{:CNOT}(), 1, 4)
push_gate!(c, Val{:H}(), 1)
push_gate!(c, Val{:T}(), 2)
push_gate!(c, Val{:S}(), 3)
push_gate!(c, Val{:H}(), 4)
push_gate!(c, Val{:T}(), 1)
push_gate!(c, Val{:H}(), 2)
push_gate!(c, Val{:H}(), 3)
push_gate!(c, Val{:Sdag}(), 4)
push_gate!(c, Val{:S}(), 3)
push_gate!(c, Val{:X}(), 4)
push_gate!(c, Val{:CNOT}(), 3, 2)
push_gate!(c, Val{:H}(), 1)
push_gate!(c, Val{:S}(), 4)
push_gate!(c, Val{:X}(), 4)

ir = @make_ircode begin
end
bir = BlockIR(ir, 4, c)
zxd = convert_to_zxd(bir)
zxg = ZXGraph(zxd)

@test plot(zxd) !== nothing
@test plot(zxg) !== nothing
@test plot(zxd; backend = :compose) !== nothing
@test plot(zxg; backend = :compose) !== nothing