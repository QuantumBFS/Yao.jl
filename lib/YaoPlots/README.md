# YaoPlots

[![CI](https://github.com/QuantumBFS/YaoPlots.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/QuantumBFS/YaoPlots.jl/actions/workflows/CI.yml)
[![Coverage](https://codecov.io/gh/QuantumBFS/YaoPlots.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/QuantumBFS/YaoPlots.jl)

## Example 1: Visualize a QBIR define in Yao

```julia
using Yao.EasyBuild, YaoPlots

# show a qft circuit
vizcircuit(qft_circuit(5))
```

If you are using a Pluto/Jupyter notebook, Atom/VSCode editor, you should see the following image in your plotting panel.

![qft](examples/qft.png)

## Example 2: Visualize a single qubit
```julia
using YaoPlots, Yao

reg = zero_state(1) |> Rx(π/8) |> Rx(π/8)
rho = density_matrix(ghz_state(2), 1)

bloch_sphere("|ψ⟩"=>reg, "ρ"=>rho; show_projection_lines=true)
```

Similarly, you will see
![bloch](examples/bloch.png)

See more [examples](examples/circuits.jl).

### Adjusting the plot attributes

Various attributes of the visualizations can be altered. 
The plot can be modified, if we change the following attributes

- `YaoPlots.CircuitStyles.linecolor[]` for line color, default value being `"#000000"` (black color)
- `YaoPlots.CircuitStyles.gate_bgcolor[]` for background color of square blocks, the default value being `"#FFFFFF"` (white color)
- `YaoPlots.CircuitStyles.textcolor[]` for text color, default value being `"#000000`
- `YaoPlots.CircuitStyles.lw[]` for line width, default value being `1` (pt)
- `YaoPlots.CircuitStyles.textsize[]` for text size, default value being `16` (pt)
- `YaoPlots.CircuitStyles.paramtextsize[]` for parameter text size, for parameterized gates, default value being `10` (pt)

For example,

```julia
using YaoPlots, Yao
YaoPlots.CircuitStyles.linecolor[] = "pink" 
YaoPlots.CircuitStyles.gate_bgcolor[] = "yellow" 
YaoPlots.CircuitStyles.textcolor[] = "#000080" # the navy blue color
YaoPlots.CircuitStyles.fontfamily[] = "JuliaMono"
YaoPlots.CircuitStyles.lw[] = 2.5
YaoPlots.CircuitStyles.textsize[] = 13
YaoPlots.CircuitStyles.paramtextsize[] = 8
		
vizcircuit(chain(3, put(1=>X), repeat(3, H), put(2=>Y), repeat(3, Rx(π/2))))
```

![attribute_example_2](examples/attr_circuit_2.svg)