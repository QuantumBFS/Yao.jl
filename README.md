# Yao

[![Build Status](https://travis-ci.org/QuantumBFS/Yao.jl.svg?branch=master)](https://travis-ci.org/QuantumBFS/Yao.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/kjagpnqoetugmuxt?svg=true)](https://ci.appveyor.com/project/Roger-luo/yao-jl)
[![Coverage Status](https://coveralls.io/repos/github/QuantumBFS/Yao.jl/badge.svg?branch=master)](https://coveralls.io/github/QuantumBFS/Yao.jl?branch=master)
[![codecov](https://codecov.io/gh/QuantumBFS/Yao.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/QuantumBFS/Yao.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://QuantumBFS.github.io/Yao.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://QuantumBFS.github.io/Yao.jl/latest)

Flexible, Extensible, Efficient Framework for Quantum Algorithm Design.

## Introduction

Yao is an open source framework for quantum algorithms design. It is designed to be **Flexible**, **Extensible** and **Efficient**. You can use **Yao** to:

- simulate quantum algorithm with circuits
- design new quantum algorithms (not limited in circuit models in principle)
- learn quantum computing

on your own classical computer, e.g a laptop.

We provide **hierarchical** APIs for quantum information
scientists to extend this framework for different purpose. The whole framework is highly **modularized**. Based on Julia's multiple dispatch feature, **any** oracle object (block) can be dispatched to possible **specialize method** which allows us to accomplish efficient simulation on classical computers.


## Installation

The package is registered. In Julia **v0.6**, you can use this command to install

```julia
julia> Pkg.add("Yao")
```

In **v0.7+**/**v1.0+**, please type `]` in the REPL to use the package mode, then type this command. Please notice that we might not be stable on **v0.7+** at the moment.

```julia
pkg> add Yao
```

## Documentation

The documentation is under development. There is only a few demos at the moment.

- [**STABLE**](https://quantumbfs.github.io/Yao.jl/stable)
- [**LATEST**](https://quantumbfs.github.io/Yao.jl/latest)


## Motivation

The growth of quantum algorithms is rapid, however, in near term future, we will still not be able to directly to test our algorithm on a real quantum computer. Moreover, the way for quantum programming is still under development. It is urgent to have a classical playground to let us explore the world of quantum computing and even quantum information.

Furthermore, adaptive algorithms like QAOA, Quantum Circuit Born Machine, etc. can not by well analyzed with pure theoretical tools, they all need numerical simulation to show its performance and how good it is.

We would like a framework that is about to have the following features:

- **Hierarchical APIs**
  - APIs from **low abstraction quantum operators** to **highly abstract** quantum oracle objects.
- **Extensibility**
  - define new operations with a minimum number of methods in principle.
  - extend with new operations on different hardware should be easy, (e.g GPUs, near term quantum devices, FPGAs, etc.)
- **Efficiency**
  - it should be fast enough to simulate quantum algorithm with at least 20 qubits on normal laptops
  - should not limit us to improve certain oracle's performance when possible.
  - We should be able to choose freely when to sacrifice memory for faster simulation and when to sacrifice the speed to simulate more qubits.
- **Transparent Interface**: users will be aware of what they are doing right through the interface, rather than using a highly abstract interface.


## Contribution

To contribute to this project, please open an [issue](https://github.com/QuantumBFS/Yao.jl/issues) first to discuss with us in case we may not accept your PR.

## Related work

[ProjectQ](https://github.com/ProjectQ-Framework/ProjectQ): An open source software framework for quantum computing

## Author

This project is an effort of QuantumBFS, an open source organization for quantum science. All the contributors are listed in the [contributors](https://github.com/QuantumBFS/Yao.jl/graphs/contributors).

## License

**Yao** is released under the Apache 2 license.
