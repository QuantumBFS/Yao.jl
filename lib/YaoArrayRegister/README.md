# YaoArrayRegister

Simulated Full Amplitude Quantum Register.

## Introduction

YaoArrayRegister.jl is a component package in the [Yao.jl](https://github.com/QuantumBFS/Yao.jl) ecosystem. It provides the most basic functionality for quantum
computation simulation in Julia and a quantum register type `ArrayReg`. You will be
able to simulate a quantum circuit alone with this package in principle.

## Installation

In Julia **v1.0+**, please type `]` in the REPL to use the package mode, then type this command:

```julia
pkg> add YaoArrayRegister
```

## Usage

This package implements `AbstractRegister` interfaces on the array storage, you can use it like other kind of registers intuitively.

## License

Apache License 2.0
