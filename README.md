# YaoPlots

[![CI](https://github.com/QuantumBFS/YaoPlots.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/QuantumBFS/YaoPlots.jl/actions/workflows/CI.yml)
[![Coverage](https://codecov.io/gh/QuantumBFS/YaoPlots.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/QuantumBFS/YaoPlots.jl)

## Example 1: Visualize a QBIR define in Yao

```julia
using YaoExtensions, YaoPlots
using Compose

# show a qft circuit
plot(qft_circuit(5))
```

If you are using a Pluto/Jupyter notebook, Atom/VSCode editor, you should see the following image in your plotting panel.

![qft](examples/qft.png)

Otherwise, you might be interested to learn [how to save it as an image](https://giovineitalia.github.io/Compose.jl/latest/tutorial/).

See more [examples](examples/circuits.jl).

## Example 2: Visualize ZX-diagrams in ZXCalculus
```julia
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

zxd = generate_example() # define a example
plot(zxd) # draw a ZX-diagram
plot(ZXGraph(zxd)) # draw a graph-like ZX-diagram
```

If you are using a Pluto/Jupyter notebook, Atom/VSCode editor, you should see the following images in your plotting panel.

![zxd](examples/demo_zxd.svg)
![zxg](examples/demo_zxg.svg)
