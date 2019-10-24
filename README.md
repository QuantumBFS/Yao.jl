# QuAlgorithmZoo

[![Build Status](https://travis-ci.org/QuantumBFS/QuAlgorithmZoo.jl.svg?branch=master)](https://travis-ci.org/QuantumBFS/QuAlgorithmZoo.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/wdbroxclvf1nhsen/branch/master?svg=true)](https://ci.appveyor.com/project/Roger-luo/qualgorithmzoo-jl/branch/master)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://quantumbfs.github.io/QuAlgorithmZoo.jl/stable/)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://quantumbfs.github.io/QuAlgorithmZoo.jl/latest/)

A curated implementation of quantum algorithms with [Yao.jl](https://github.com/QuantumBFS/Yao.jl)

*Note*: part of functionalities has been moved to [YaoExtensions](https://github.com/QuantumBFS/YaoExtensions.jl).

## Installation

QuAlgorithmZoo.jl is not registered yet, please use the following command:

```julia
pkg> add https://github.com/QuantumBFS/QuAlgorithmZoo.jl.git
```

Disclaimer: **this package is still under development and needs further polish.**

## Contents

- [x] [QFT](https://github.com/QuantumBFS/YaoExtensions.jl)
- [x] Phase Estimation
- [x] Imaginary Time Evolution Quantum Eigensolver
- [x] Variational Quantum Eigensolver
- [x] Hadamard Test
- [x] State Overlap Algorithms
- [x] Quantum SVD

In examples folder, you will find

- [x] HHL
- [x] QAOA
- [x] Quantum Circuit Born Machine
- [x] QuGAN
- [x] Shor
- [x] Grover search

- [x] [QuODE](https://github.com/QuantumBFS/QuDiffEq.jl)
- [x] [TensorNetwork Inspired Circuits](https://github.com/GiggleLiu/QuantumPEPS.jl)

## License

QuAlgorithmZoo.jl is released under Apache License 2.0.
