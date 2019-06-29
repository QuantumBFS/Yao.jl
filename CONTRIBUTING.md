# Notes for Yao Contributors

Hi! Welcome to Yao's quantum software community and thanks for trying Yao.
Yao is a framework written in [Julia](https://julialang.org/) language, you
can find Julia tutorials on [Julia's official website](https://julialang.org/learning/).

## Contributor Checklist
If you are already familiar with Julia itself, and you wish to be a contributor of Yao, here
are some guide on how to open a PR and get reviewed.

- Create a [GitHub account](https://github.com/signup/free)
- [Fork Yao](https://github.com/QuantumBFS/Yao.jl/fork) or [other component packages](#Address-Your-Contribution)
- Install Julia and type the following command in your Julia REPL's pkg mode (press `]` after you open the REPL)

```julia
(v1.1) pkg> dev https://github.com/<your account>/<package name>.jl.git
```

- open the `.julia/dev/<package name>` folder, this is the latest develop version of the package
- Learn to use [git](https://git-scm.com/), the version control system used by GitHub and the Yao project. Try a turtorial such as the one [provided by GitHub](https://try.github.io/levels/1/challenges/1)
- For more detailed tips, read the [submission guide](#Submitting-contributions) below.
- Relax and Happy coding!

## Submitting contributions
### Writing tests
There are never enough tests. Track code coverate at Coveralls for each [componenet](#Components-of-the-whole-Yao-Project) of Yao, and
help improve it.

1. Click the coverall badage at each package's README
2. Browse through the source files and find some untested functionality (highlighted in red) that you think you might be able to write a test for
3. write a test that exercises this functionality---you can add your test to one of the existing files, or start a new one, whichever seems most appropriate to you. If you are adding a new test file, make sure you include it in the list of tests `test/runtests.jl`. [stdlib/Test](https://docs.julialang.org/en/latest/stdlib/Test/) may be helpful in explaining how the test infrastructure works.
4. Run `test <package name>` your REPL's pkg mode to run the tests
5. Submit the test as a pull request (PR)

### Improving documentation

By *contribuing documentation to Yao*, you are agreeing to release it under [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

Yao's documentation source file are stored in `docs/` directory, the docstrings are in each component packages. Documentation is built with [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) and the examples are written in [Julia flavoured markdown](https://docs.julialang.org/en/v1/stdlib/Markdown/index.html) with [Weave.jl](https://github.com/mpastell/Weave.jl), the HTML documentation can be built locally by running

```sh
julia --project=docs docs/make.jl
```

from Yao's root directory.

### Contributing to core functionality in Yao's Components
By *contributing code to Yao*, you are agreeing to release it under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)

Yao uses [GitHub issues](https://github.com/QuantumBFS/Yao.jl/issues) of the meta package Yao.jl to track and discuss problems, feature requests. Pull requests (PR) should be submitted to related package. Yao can make pull requests for incomplete features to get code review. **The convention is to prefix the pull request with "WIP:" for Work In Progress, or "RFC:" for Request for Comments when work is completed and ready for merging. This will prevent accidental merging of work that is in progress.**

### Core Formatting Guidelines

We currently loosely follow the official [Code Formatting Guidelines](https://github.com/JuliaLang/julia/blob/master/CONTRIBUTING.md#code-formatting-guidelines), since we do not have a formatter in the CI, we do not strictly require
our contributors to follow this guidelines, it is mainly depends on the reviewer.

## Components of the whole Yao Project
The whole Yao project is an ecosystem of several packages, which is listed below.

### Component Packages

Yao is a meta-package over several component packages, here is a cheatsheet to help you address which component package you might be interested in.

- [YaoBase](https://github.com/QuantumBFS/YaoBase.jl) Abstract interface definitions and some common tools, this includes:
  - the interface of quantum registers (marked by `@interface` macro)
  - custom error handling
  - common utilities including: math functions for quantum science, common constant matrices in quantum physics

- [YaoArrayRegister](https://github.com/QuantumBFS/YaoArrayRegister.jl) The implementation of quantum simulator instructions and the full amplitude simulated quantum register.
- [YaoBlocks](https://github.com/QuantumBFS/YaoBlocks.jl) The implementation of Yao's **Quantum Block IR** and some specialization for certain quantum blocks.

### External Dependencies maintained by QuantumBFS

We also developed some more general tools for Yao, this includes:

- [BitBasis](https://github.com/QuantumBFS/BitBasis.jl) Types and operations for basis represented by bits in linear algebra.
- [LuxurySparse](https://github.com/QuantumBFS/LuxurySparse.jl) High performance extension for sparse matrices.
- [CacheServers](https://github.com/QuantumBFS/CacheServers.jl) Definition and implementation of some Cache Servers.

### Packages under Early Development

- [CuYao](https://github.com/QuantumBFS/CuYao.jl) CUDA extension for Yao
- [QuDiffEq](https://github.com/QuantumBFS/QuDiffEq.jl) Quantum algorithms for solving differential equations.
