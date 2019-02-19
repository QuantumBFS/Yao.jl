# YaoArrayRegister

[![Build Status](https://travis-ci.com/QuantumBFS/YaoArrayRegister.jl.svg?branch=master)](https://travis-ci.com/QuantumBFS/YaoArrayRegister.jl)
[![Codecov](https://codecov.io/gh/QuantumBFS/YaoArrayRegister.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/QuantumBFS/YaoArrayRegister.jl)
[![Coveralls](https://coveralls.io/repos/github/QuantumBFS/YaoArrayRegister.jl/badge.svg?branch=master)](https://coveralls.io/github/QuantumBFS/YaoArrayRegister.jl?branch=master)


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

This package implements `AbstractRegister` interface defined in [YaoBase](https://github.com/QuantumBFS/YaoBase.jl), you can use it like other kind of registers intuitively.

## License

Apache License 2.0
