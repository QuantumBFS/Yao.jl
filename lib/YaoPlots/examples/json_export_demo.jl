#!/usr/bin/env julia
# Demo: Export Yao circuit to JSON file using the JSONBackend

using Yao
using YaoPlots

# Create a quantum circuit
circuit = chain(4,
    put(1=>H),
    put(2=>Rx(π/4)),
    control(4, 1, 2=>X),
    put((2,3)=>SWAP),
    put(4=>Measure(1))
)

# Export to JSON (automatically saves)
filename = joinpath(@__DIR__, "example_circuit.json")
backend = YaoPlots.CircuitStyles.JSONBackend(filename)
vizcircuit(circuit; backend=backend)