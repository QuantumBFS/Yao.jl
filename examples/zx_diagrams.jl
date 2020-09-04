using ZXCalculus, YaoPlots
using Compose

function generate_example()
    zxd = ZXDiagram(4)
    push_gate!(zxd, Val{:Z}(), 1, 3//2)
    push_gate!(zxd, Val{:H}(), 1)
    push_gate!(zxd, Val{:Z}(), 1, 1//2)
    push_gate!(zxd, Val{:H}(), 4)
    push_gate!(zxd, Val{:CZ}(), 4, 1)
    push_gate!(zxd, Val{:CNOT}(), 1, 4)
    push_gate!(zxd, Val{:H}(), 1)
    push_gate!(zxd, Val{:H}(), 4)
    push_gate!(zxd, Val{:Z}(), 1, 1//4)
    push_gate!(zxd, Val{:Z}(), 4, 3//2)
    push_gate!(zxd, Val{:X}(), 4, 1//1)
    push_gate!(zxd, Val{:H}(), 1)
    push_gate!(zxd, Val{:Z}(), 4, 1//2)
    push_gate!(zxd, Val{:X}(), 4, 1//1)
    push_gate!(zxd, Val{:Z}(), 2, 1//2)
    push_gate!(zxd, Val{:CNOT}(), 3, 2)
    push_gate!(zxd, Val{:H}(), 2)
    push_gate!(zxd, Val{:CNOT}(), 3, 2)
    push_gate!(zxd, Val{:Z}(), 2, 1//4)
    push_gate!(zxd, Val{:Z}(), 3, 1//2)
    push_gate!(zxd, Val{:H}(), 2)
    push_gate!(zxd, Val{:H}(), 3)
    push_gate!(zxd, Val{:Z}(), 3, 1//2)
    push_gate!(zxd, Val{:CNOT}(), 3, 2)

    return zxd
end

zxd = generate_example()
p1 = plot(zxd)
p1 |> SVG("examples/demo_zxd.svg")
p2 = plot(ZXGraph(zxd))
p2 |> SVG("examples/demo_zxg.svg")