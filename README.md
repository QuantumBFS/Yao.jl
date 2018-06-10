# Yao

[![Build Status](https://travis-ci.org/QuantumBFS/Yao.jl.svg?branch=master)](https://travis-ci.org/QuantumBFS/Yao.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/kjagpnqoetugmuxt?svg=true)](https://ci.appveyor.com/project/Roger-luo/yao-jl)
[![Coverage Status](https://coveralls.io/repos/github/QuantumBFS/Yao.jl/badge.svg?branch=master)](https://coveralls.io/github/QuantumBFS/Yao.jl?branch=master)
[![codecov](https://codecov.io/gh/QuantumBFS/Yao.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/QuantumBFS/Yao.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://QuantumBFS.github.io/Yao.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://QuantumBFS.github.io/Yao.jl/latest)

Flexible, Extensible, Efficient Framework for Quantum Algorithm Design.

## Project Goals

Quantum computing is approaching. However, in the near term future, we will not be able to directly test our algorithm on a real quantum computer. Moreover, the way for quantum programming is still under development. We will need a classical playground to let us explore the world of quantum algorithms, quantum programming and even quantum information. Furthermore, recently progress on self-adaptive quantum algorithms like QAOA, quantum circuit born machines, etc. can not be analysed directly by theoretical tools, and they require numerical simulation.

Our framework, Yao, aims to provide flexible utilities for simulating your own algorithms, which means you should be able to simulate your quantum algorithm with any possible numerical approach that maximize the machine performance without making everything a black box. We provide hierachical APIs for different development purpose. By overloading interfaces and defining new subtypes you will be able to create whatever you want for your simulation.

## Contribution

We do not accept PR at the moment. But if there is any comments please leave us an issue. We will start accepting PRs after v0.2.

## Installation

The package is registered. Use this command to install

```julia
julia> Pkg.add("Yao")
```

## Documentation

The documentation is under development. There is only a few demos at the moment.

- [**STABLE**](https://quantumbfs.github.io/Yao.jl/stable)
- [**LATEST**](https://quantumbfs.github.io/Yao.jl/latest)
