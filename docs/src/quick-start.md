# Quick Start

In this quick start, we list several common use cases for Yao before you
go deeper into the manual.

## Create a quantum register/state

A register is an object that describes a device with an internal state. See [Registers](@ref registers)
for more details. Yao use registers to represent quantum states. The most common register
is the [`ArrayReg`](@ref), you can create it by feeding a state vector to it, e.g

```@repl quick-start
using Yao
zero_state(5)  # |00000⟩
```
The internal quantum state can be accessed via [`statevec`](@ref) method
```@repl quick-start
statevec(ghz_state(2))
```
Similarly, you can use [`rand_state`](@ref), [`uniform_state`](@ref), [`product_state`](@ref), [`ghz_state`](@ref) to create a random state, a uniform state, a product state, and a GHZ state, respectively. Not only qubit states, qudits and batch states are also supported.
For more functionalities about registers please refer to the manual of [Registers](@ref registers).

## Create quantum circuit

Yao introduces an abstract representation for linear maps, called "block"s, which can be used to represent quantum circuits, Hamiltonians, and other quantum operations. To check the matrix representation of a quantum gate, you can define a symbolic variable and then use the [`mat`](@ref) function to get the matrix representation of the gate.

```@repl quick-start
@vars θ  # define a symbolic variable
mat(Rx(θ))  # the matrix representation of Rx gate
mat(shift(θ))  # the matrix representation of shift gate
mat(Basic, H)  # the matrix representation of H gate, `Basic` is the symbol type
```

By composing these blocks with composite blocks, such as [`chain`](@ref), [`control`](@ref) and [`put`](@ref), one can create a quantum circuit. For example, the following is the quantum Fourier transform circuit.

```@repl quick-start
A(i, j) = control(i, j=>shift(2π/(1<<(i-j+1))))  # a cphase gate
B(n, k) = chain(n, j==k ? put(k=>H) : A(j, k) for j in k:n)
qft(n) = chain(B(n, k) for k in 1:n)
circuit = qft(5)  # a 5-qubit QFT circuit
mat(circuit)  # the matrix representation of the circuit
final_state = apply!(zero_state(5), circuit)  # apply the circuit to a zero state
measure!(final_state)  # measure the final state, which will collapse the state
```

More details about available blocks can be found in the manual of [Blocks](@ref blocks).

To visualize the above quantum circuits in [`VSCode`](https://code.visualstudio.com/), [`Jupyter`](https://jupyter.org/) notebook or [`Pluto`](https://github.com/fonsp/Pluto.jl) notebook, you can use the [`vizcircuit`](@ref) function.
```@example quick-start
vizcircuit(circuit)  # show a qft circuit
```
More details about the plotting can be found in the manual: [Quantum Circuit Visualization](@ref).

## Create Hamiltonian

We can create a simple Heisenberg Hamiltonian on 1D chain as following

```@repl quick-start
h = sum([sum([kron(5, i=>G, mod1(i+1, 5)=>G) for G in [X, Y, Z]]) for i in 1:5])
mat(h)  # the matrix representation of the Hamiltonian
h[bit"01010", bit"01010"]  # a diagonal element of the Hamiltonian
h[:, bit"01010"]  # a column of the Hamiltonian
expect(h, apply!(zero_state(5), circuit))  # the expectation value of the Hamiltonian
```

## Differentiating a quantum circuit

`Yao` has an efficient built-in automatic differentiation engine, which allows one obtain
gradients of a loss function by attaching a `'` after [`expect`](@ref)
or [`fidelity`](@ref), e.g

To obtain the gradient of the quantum Fourier transform circuit with respect to its parameters, one can use the following code
```@repl quick-start
grad_state, grad_circuit_params = expect'(h, zero_state(5)=>circuit)
```
where `h` is the target observable, `zero_state(5)` is the initial state, `circuit` is the quantum Fourier transform circuit to be differentiated.
The return value is a vector, each corresponding to the gradient of the loss function with respect to a parameter in the circuit.
The list of parameters can be obtained by [`parameters`](@ref) function.
```@repl quick-start
parameters(circuit)
```

To obtain the gradient of the fidelity between a state parameterized by a quantum circuit and a target state, one can use the following code

```@repl quick-start
((grad_state1, grad_circuit1), grad_state2) = fidelity'(zero_state(5)=>circuit, ghz_state(5))
```
where `zero_state(5)` is the initial state, `circuit` is the quantum Fourier transform circuit, `ghz_state(5)` is the target state.

The automatic differentiation functionality can also be accessed by interfacing with the machine learning libraries [`Zygote`](https://github.com/FluxML/Zygote.jl). Please refer to the manual of [Automatic Differentiation](@ref) for more details.