# Quick Start

In this quick start, we list several common use cases for Yao before you
go deeper into the manual.

## Create a quantum register/state

A register is an object that describes a device with an internal state. See [Registers](@ref registers)
for more details. Yao use registers to represent quantum states. The most common register
is the [`ArrayReg`](@ref), you can create it by feeding a state vector to it, e.g

```@repl quick-start
using Yao
ArrayReg(rand(ComplexF64, 2^3))
zero_state(5)
rand_state(5)
product_state(bit"10100")
ghz_state(5)
```

the internal quantum state can be accessed via [`statevec`](@ref) method

```@repl quick-start
statevec(ghz_state(2))
```

for more functionalities about registers please refer to the manual of [`registers`](@ref).

## Create quantum circuit with Yao blocks

Yao uses the quantum "block"s to describe quantum circuits, e.g
the following code creates a 2-qubit circuit

```@repl quick-start
chain(2, put(1=>H), put(2=>X))
```

where `H` gate is at 1st qubit, `X` gate is at 2nd qubit.
A more advanced example is the quantum Fourier transform circuit

```@repl quick-start
A(i, j) = control(i, j=>shift(2π/(1<<(i-j+1))))
B(n, k) = chain(n, j==k ? put(k=>H) : A(j, k) for j in k:n)
qft(n) = chain(B(n, k) for k in 1:n)
qft(3)
```

## Create Hamiltonian with Yao blocks

the quantum "block"s are expressions on quantum operators, thus, it can
also be used to represent a Hamiltonian, e.g we can create a simple Ising
Hamiltonian on 1D chain as following

```@repl quick-start
sum(kron(5, i=>Z, mod1(i+1, 5)=>Z) for i in 1:5)
```

## Automatic differentiate a Yao block

Yao has its own automatic differentiation rule implemented, this allows one obtain
gradients of a loss function by simply putting a `'` mark following [`expect`](@ref)
or [`fidelity`](@ref), e.g

```@repl quick-start
expect'(X, zero_state(1)=>Rx(0.2))
```

or for fidelity

```@repl quick-start
fidelity'(zero_state(1)=>Rx(0.1), zero_state(1)=>Rx(0.2))
```

## Combine Yao with ChainRules/Zygote


## Symbolic calculation with Yao block
Yao supports symbolic calculation of quantum circuit via `SymEngine`. We can show


## Plot quantum circuits

The [YaoPlots]() in Yao's ecosystem provides plotting for quantum circuits and ZX diagrams.

```@example quick-start
using Yao.EasyBuild, YaoPlots
using Compose

# show a qft circuit
Compose.SVG(plot(qft_circuit(5)))
```

## Convert quantum circuits to tensor network
## Simplify quantum circuit with ZX calculus
