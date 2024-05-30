# Quick Start

In this quick start, we list several common use cases for Yao before you
go deeper into the manual.

## Create a quantum register/state

A register is an object that describes a device with an internal state. See [Registers](@ref registers)
for more details. Yao use registers to represent quantum states. The most common register
is the [`ArrayReg`](@ref), you can create it by feeding a state vector to it, e.g

```@repl quick-start
using Yao
ArrayReg(randn(ComplexF64, 2^3))  # a random unnormalized 3-qubit state
zero_state(5)  # |00000⟩
rand_state(5)  # a random state
product_state(bit"10100")  # |10100⟩
ghz_state(5)  # (|00000⟩ + |11111⟩)/√2
```

the internal quantum state can be accessed via [`statevec`](@ref) method

```@repl quick-start
statevec(ghz_state(2))
```

for more functionalities about registers please refer to the manual of [Registers](@ref registers).

## Create quantum circuit

Yao introduces an abstract representation for linear maps, called "block"s, which can be used to represent quantum circuits, Hamiltonians, and other quantum operations. The following code creates a 2-qubit circuit

```@repl quick-start
chain(2, put(1=>H), put(2=>X))
```

where `H` gate is at 1st qubit, `X` gate is at 2nd qubit.
A more advanced example is the quantum Fourier transform circuit

```@repl quick-start
A(i, j) = control(i, j=>shift(2π/(1<<(i-j+1))))  # a cphase gate
B(n, k) = chain(n, j==k ? put(k=>H) : A(j, k) for j in k:n)
qft(n) = chain(B(n, k) for k in 1:n)
circuit = qft(3)  # a 3-qubit QFT circuit
mat(circuit)  # the matrix representation of the circuit
apply!(zero_state(3), circuit)  # apply the circuit to a zero state
```

More details about available blocks can be found in the manual of [Blocks](@ref blocks).

## Create Hamiltonian

We can create a simple Ising Hamiltonian on 1D chain as following

```@repl quick-start
h = sum([kron(5, i=>Z, mod1(i+1, 5)=>Z) for i in 1:5])  # a 5-qubit Ising Hamiltonian
mat(h)  # the matrix representation of the Hamiltonian
```

## Differentiating a quantum circuit

Yao has its own automatic differentiation rule implemented, this allows one obtain
gradients of a loss function by simply putting a `'` mark following [`expect`](@ref)
or [`fidelity`](@ref), e.g

To obtain the gradient of the quantum Fourier transform circuit with respect to its parameters, one can use the following code
```@repl quick-start
grad_state, grad_circuit_params = expect'(kron(X, X, I2) + kron(I2, X, X), zero_state(3)=>qft(3))
```
where `kron(X, X, I2) + kron(I2, X, X)` is the target Hamiltonian, `zero_state(3)` is the initial state, `qft(3)` is the quantum Fourier transform circuit.
The return value is a vector, each corresponding to the gradient of the loss function with respect to a parameter in the circuit.
The list of parameters can be obtained by [`parameters`](@ref) function.
```@repl quick-start
parameters(qft(3))
```

To obtain the gradient of the fidelity between a state parameterized by a quantum circuit and a target state, one can use the following code

```@repl quick-start
((grad_state1, grad_circuit1), grad_state2) = fidelity'(zero_state(3)=>qft(3), ghz_state(3))
```
where `zero_state(3)` is the initial state, `qft(3)` is the quantum Fourier transform circuit, `ghz_state(3)` is the target state.

The automatic differentiation functionality can also be accessed by interfacing with the machine learning libraries [`Zygote`](https://github.com/FluxML/Zygote.jl).

## Plot quantum circuits

The component package `YaoPlots` provides plotting for quantum circuits and ZX diagrams. You can use it to visualize your quantum circuits in [`VSCode`](https://code.visualstudio.com/), [`Jupyter`](https://jupyter.org/) notebook or [`Pluto`](https://github.com/fonsp/Pluto.jl) notebook.

```@example quick-start
using Yao.EasyBuild, Yao.YaoPlots
using Compose

# show a qft circuit
vizcircuit(qft_circuit(5))
```

More details about the plotting can be found in the manual: [Quantum Circuit Visualization](@ref).