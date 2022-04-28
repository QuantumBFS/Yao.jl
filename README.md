<div align="center"> <img
src="https://yaoquantum.org/assets/logo.png"
alt="Yao Logo" width="400"></img>
</div>


[![CI][main-ci-img]][main-ci-url]
[![codecov][main-codecov-img]][main-codecov-url]
[![][docs-stable-img]][docs-stable-url]
[![][docs-dev-img]][docs-dev-url]
[![Unitary Fund][unitary-fund-img]](http://unitary.fund)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

**Yao** Extensible, Efficient Quantum Algorithm Design for Humans.

## Introduction

Yao is an open source framework that aims to empower quantum information research with software tools. It is designed with following in mind:

- quantum algorithm design;
- quantum [software 2.0](https://medium.com/@karpathy/software-2-0-a64152b37c35);
- quantum computation education.

**We are in an early-release beta. Expect some adventures and rough edges.**

## Try your first Yao program

A 3 line Quantum Fourier Transformation with [Quantum Blocks](http://docs.yaoquantum.org/dev/man/blocks.html):

```julia
A(i, j) = control(i, j=>shift(2π/(1<<(i-j+1))))
B(n, k) = chain(n, j==k ? put(k=>H) : A(j, k) for j in k:n)
qft(n) = chain(B(n, k) for k in 1:n)
```

## Installation

<p>
Yao is a &nbsp;
    <a href="https://julialang.org">
        <img src="https://raw.githubusercontent.com/JuliaLang/julia-logo-graphics/master/images/julia.ico" width="16em">
        Julia Language
    </a>
    &nbsp; package. To install Yao,
    please <a href="https://docs.julialang.org/en/v1/manual/getting-started/">open
    Julia's interactive session (known as REPL)</a> and press <kbd>]</kbd> key in the REPL to use the package mode, then type the following command
</p>

For stable release

```julia
pkg> add Yao
```

For current master

```julia
pkg> add Yao#master
```

If you have problem to install the package, please [file us an issue](https://github.com/QuantumBFS/Yao.jl/issues/new).

For CUDA support, see [CuYao.jl](https://github.com/QuantumBFS/CuYao.jl).

For tensor network based simulations, see [YaoToEinsum.jl](https://github.com/QuantumBFS/YaoToEinsum.jl).

## Documentation

### [Tutorial](https://yaoquantum.org/tutorials/) | Learn Quantum Computing with Yao

### Algorithm Zoo

Some quantum algorithms are implemented with Yao in [QuAlgorithmZoo](https://github.com/QuantumBFS/QuAlgorithmZoo.jl).

### Online Documentation

- [**STABLE**](https://quantumbfs.github.io/Yao.jl/stable) — most recently tagged version of the documentation.
- [**LATEST**](https://quantumbfs.github.io/Yao.jl/latest) — in-development version of the documentation.

## Communication

- Github issues: Please feel free to ask questions and report bugs, feature request in issues
- Slack: you can [join julia's slack channel](https://julialang.org/slack/) and ask Yao related questions in `#yao-dev` channel.
- Julia discourse: You can also ask questions on [julia discourse](https://discourse.julialang.org/) or the [Chinese discourse](https://discourse.juliacn.com/)

## The Team

This project is an effort of QuantumBFS, an open source organization for quantum science. Yao is currently maintained by [Xiu-Zhe (Roger) Luo](https://github.com/Roger-luo) and [Jin-Guo Liu](https://github.com/GiggleLiu) with contributions from open source community. All the contributors are listed in the [contributors](https://github.com/QuantumBFS/Yao.jl/graphs/contributors).

## Cite Yao
If you use Yao in teaching and research, please cite our work:

```bib
@article{YaoFramework2019,
  title={Yao.jl: Extensible, Efficient Framework for Quantum Algorithm Design},
  author={Xiu-Zhe Luo and Jin-Guo Liu and Pan Zhang and Lei Wang},
  journal={arXiv preprint arXiv:1912.10877},
  year={2019}
}
```

## License

**Yao** is released under the Apache 2 license.

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://QuantumBFS.github.io/Yao.jl/dev
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://QuantumBFS.github.io/Yao.jl/stable

[unitary-fund-img]: https://img.shields.io/badge/Supported%20By-UNITARY%20FUND-brightgreen.svg?style=flat-the-badge

[main-url]: https://github.com/QuantumBFS/Yao.jl
[main-ci-img]: https://github.com/QuantumBFS/Yao.jl/actions/workflows/CI.yml/badge.svg
[main-ci-url]: https://github.com/QuantumBFS/Yao.jl/actions/workflows/CI.yml
[main-codecov-img]: https://codecov.io/gh/QuantumBFS/Yao.jl/branch/master/graph/badge.svg
[main-codecov-url]: https://codecov.io/gh/QuantumBFS/Yao.jl
