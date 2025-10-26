```@meta
CurrentModule = YaoPlots
DocTestSetup = quote
    using Yao
    using Yao: YaoBlocks, YaoArrayRegister, YaoSym
    using YaoBlocks
    using YaoArrayRegister
    using YaoPlots
end
```

# Quantum Circuit Visualization

`YaoPlots` is the Quantum circuit visualization component for Yao.


## Examples
#### Example 1: Visualize a QBIR define in Yao

```@example plot
using Yao.EasyBuild, YaoPlots

# show a qft circuit
vizcircuit(qft_circuit(5))
```

If you are using a Pluto/Jupyter notebook, Atom/VSCode editor, you should see the above image in your plotting panel.

#### Example 2: Visualize a single qubit
```@example plot
using YaoPlots, Yao

reg = zero_state(1) |> Rx(π/8) |> Rx(π/8)
rho = density_matrix(ghz_state(2), 1)

bloch_sphere("|ψ⟩"=>reg, "ρ"=>rho; show_projection_lines=true)
```

See more [examples](lib/YaoPlots/examples/circuits.jl).

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

```@example plot
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

## JSON Export

YaoPlots supports exporting circuit visualizations to JSON format for use with external rendering tools like Typst.

```@example plot
using Yao, YaoPlots

# Create a circuit
circuit = chain(3, put(1=>X), put(2=>H), control(3, 1, 2=>X))

# Export to JSON
backend = YaoPlots.CircuitStyles.JSONBackend("circuit.json")
vizcircuit(circuit; backend=backend)
```

The JSON output contains high-level gate commands with semantic information (gate types, qubit positions, labels) that can be rendered by custom visualization tools. A Typst template (`Yao/lib/YaoPlots/examples/render_circuit.typ`) is provided in the examples directory.

## Circuit Visualization
```@docs
vizcircuit
plot
```

## Bloch Sphere Visualization

```@docs
CircuitStyles
bloch_sphere
BlochStyles
```

## Themes
```@docs
darktheme!
lighttheme!
```
