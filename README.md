# YaoPlots

[![Build Status](https://travis-ci.com/QuantumBFS/YaoPlots.jl.svg?branch=master)](https://travis-ci.com/QuantumBFS/YaoPlots.jl)
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
