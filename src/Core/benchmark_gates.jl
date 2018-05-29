using BenchmarkTools
include("gates.jl")

v = randn(Complex128, 1<<16)
bench = BenchmarkGroup()
xg = xgate(16, 2)
#bg["indices_with"] = @benchmarkable indices_with(2, bss)
bg = bench["Basic Gate"] = BenchmarkGroup()
bg["X"] = @benchmarkable xgate(16, 2)
bg["Y"] = @benchmarkable ygate(16, 2)
bg["Z"] = @benchmarkable zgate(16, 2)
bg["X*v"] = @benchmarkable $xg * v

############# controlled gates ##################
bg = bench["CZ Gate"] = BenchmarkGroup()
bg["CZ"] = @benchmarkable czgate(Complex128,16, 3, 7)
bg["Diag-CZ"] = @benchmarkable controlled_U1(16, PAULI_Z, [3], 7)
bg["General-CZ"] = @benchmarkable general_controlled_gates(16, [P1], [7], [PAULI_Z], [3])

bg = bench["CX Gate"] = BenchmarkGroup()
bg["CNOT"] = @benchmarkable cxgate(Complex128,16, 7, 3)
bg["PM-CNOT"] = @benchmarkable controlled_U1(16, PAULI_X, [3], 7)
bg["General-CNOT"] = @benchmarkable general_controlled_gates(16, [P1], [7], [PAULI_X], [3])

bg = bench["CY Gate"] = BenchmarkGroup()
bg["CY"] = @benchmarkable cygate(Complex128,16, 7, 3)
bg["PM-CY"] = @benchmarkable controlled_U1(16, PAULI_Y, [3], 7)
bg["General-CY"] = @benchmarkable general_controlled_gates(16, [P1], [7], [PAULI_Y], [3])

##### TOFFOLI gate
bg = bench["Toffoli Gate"] = BenchmarkGroup()
bg["Toffoli"] = @benchmarkable toffoligate(16, 2, 3, 1)
bg["General-Toffoli"] = @benchmarkable general_controlled_gates(16, [P1, P1], [2,3], [PAULI_X], [1])

showall(run(bench, verbose=true))
