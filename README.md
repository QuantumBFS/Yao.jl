<div align="center"> <img
src="https://rawgit.com/QuantumBFS/Yao.jl/master/docs/src/assets/logo.svg"
alt="Yao Logo" width="210"></img>
<h1>Yao</h1>
</div>


[![Build Status](https://travis-ci.org/QuantumBFS/Yao.jl.svg?branch=master)](https://travis-ci.org/QuantumBFS/Yao.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/kjagpnqoetugmuxt?svg=true)](https://ci.appveyor.com/project/Roger-luo/yao-jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://QuantumBFS.github.io/Yao.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://QuantumBFS.github.io/Yao.jl/latest)

Extensible, Efficient Quantum Algorithm Design for Humans.

## Introduction

Yao is an open source framework for

- quantum algorithm design;
- quantum [software 2.0](https://medium.com/@karpathy/software-2-0-a64152b37c35);
- quantum computation education.

**We are in an early-release beta. Expect some adventures and rough edges.**

## Installation

Yao is a [julia](https://julialang.org/) language package. To install Yao, please [open Julia's interactive session (known as REPL)](https://docs.julialang.org/en/v1/manual/getting-started/) and type `]` in the REPL to use the package mode, then type this command:

```julia
pkg> add Yao
```

For CUDA support, see [CuYao.jl](https://github.com/QuantumBFS/CuYao.jl).

## Getting Started

[Examples: understand Yao's code for quantum algorithms](https://quantumbfs.github.io/Yao.jl/stable/#Getting-Started-1)

## Documentation

- [**STABLE**](https://quantumbfs.github.io/Yao.jl/stable)
- [**LATEST**](https://quantumbfs.github.io/Yao.jl/latest)

## Communication

- Github issues: Please feel free to ask questions and report bugs, feature request in issues
- slack: you can [join julia's slack channel](https://slackinvite.julialang.org/) and ask Yao related questions in `#yao-dev` channel.
- Julia discourse: You can also ask questions on [julia discourse](https://discourse.julialang.org/) or the [Chinese discourse](https://discourse.juliacn.com/)

## Algoritm Zoo

Some quantum algorithms are implemented with Yao in [QuAlgorithmZoo](https://github.com/QuantumBFS/QuAlgorithmZoo.jl).

## Motivation
Comparing with state of art quantum simulators, our library is inspired by quantum circuit optimization.
Variational quantum optimization algorithms like quantum circuit Born machine ([QCBM](https://arxiv.org/abs/1804.04168)), quantum approximate optimization algorithm ([QAOA](http://arxiv.org/abs/1411.4028)), variational quantum eigensolver ([VQE](https://doi.org/10.1038/ncomms5213)) and quantum circuit learning ([QCL](http://arxiv.org/abs/1803.00745)) et. al. are promising killer apps on a near term quantum computers.
These algorithms require the flexibility to tune parameters and have well defined patterns such as "Arbitrary Rotation Block" and "CNOT Entangler".

In Yao, we call these patterns "blocks". If we regard every gate or gate pattern as a "block", then the framework can

* be flexible to dispatch parameters,
* cache matrices of blocks to speed up future runs,
* allow hierarchical design of quantum algorithms

Thanks to Julia's duck type and multiple dispatch features, user can

* easily **extend** the block system by overloading specific interfaces
* quantum circuit blocks can be dispatched to some **special method** to improve the performance in specific case (e.g. customized repeat block of H gate).



## Features

Yao is a framework that is about to have the following features:

- **Extensibility**
  - define new operations with a minimum number of methods in principle.
  - extend with new operations on different hardware should be easy, (e.g GPUs, near term quantum devices, FPGAs, etc.)
- **Efficiency**
  - comparing with python, julia have no significant overhead on small scale circuit.
  - special optimized methods are dispatched to frequently used blocks.
  - double interfaces "apply!" and "cache server + mat" allow us to choose freely when to sacrifice memory for faster simulation and when to sacrifice the speed to simulate more qubits.
- **Easy to Use**
  - As a white-box simulator, rather than using a black box, users will be aware of what their simulation are doing right through the interface.
  - **Hierarchical APIs** from **low abstraction quantum operators** to **highly abstract** circuit block objects.

## Architecture

Yao is a meta package based on several component packages in order to provide a highly modularized architecture, researchers and developers can extend the framework with different component packages for different purposes with minimal effort. The component packages includes:

- [YaoBase](https://github.com/QuantumBFS/YaoBase.jl) Interface definition and basic toolkits for registers.
- [YaoBlocks](https://github.com/QuantumBFS/YaoBlocks.jl) Standard basic quantum circuit simulator building blocks.
- [YaoArrayRegister](https://github.com/QuantumBFS/YaoArrayRegister.jl) Simulated Full Amplitude Quantum Register

## Contribution

To contribute to this project, please open an [issue](https://github.com/QuantumBFS/Yao.jl/issues) first to discuss with us in case we may not accept your PR.

## Author

This project is an effort of QuantumBFS, an open source organization for quantum science. All the contributors are listed in the [contributors](https://github.com/QuantumBFS/Yao.jl/graphs/contributors).

## License

**Yao** is released under the Apache 2 license.
