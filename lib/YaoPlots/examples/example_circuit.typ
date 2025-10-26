// Example: Visualizing a Yao quantum circuit with Typst
// This document renders the circuit exported from json_export_demo.jl

#import "render_circuit.typ": render-circuit

// Read the JSON file
#let circuit_data = json("example_circuit.json")

#set page(width: auto, height: auto, margin: 2cm)
#set text(size: 12pt)

= Quantum Circuit Visualization

This circuit was generated from Yao.jl and exported to JSON format.

#align(center)[
  #render-circuit(circuit_data)
]

== Circuit Components

The circuit includes:
- Hadamard gate (H)
- Rotation gate Rx(π/4)
- Controlled-NOT (CNOT)
- SWAP gate
- Measurement

The JSON export contains #circuit_data.len() drawing instructions.

