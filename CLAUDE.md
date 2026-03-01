# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Yao.jl is a modular quantum computing framework for Julia. It is a monorepo containing the main `Yao` umbrella package plus six component packages under `lib/`.

## Package Dependency Hierarchy

```
YaoAPI              (abstract interfaces, no Yao deps)
  └─ YaoArrayRegister  (array-based quantum register/state vector simulation)
       └─ YaoBlocks       (circuit blocks: gates, controls, composition)
            ├─ YaoSym         (symbolic computation via SymEngine)
            ├─ YaoPlots       (circuit visualization via Luxor)
            └─ YaoToEinsum    (tensor network conversion via OMEinsum)
                 └─ Yao          (umbrella: re-exports all + EasyBuild)
```

Each `lib/<Package>/` has its own `Project.toml`, `src/`, and `test/` directory.

## Common Commands

All commands assume you are in the repo root.

```bash
# Initialize local dev environment (develops all lib packages)
make init

# Run full test suite (all packages)
make test

# Test a single sub-package
julia --project -e 'using Pkg; Pkg.test("YaoBlocks")'

# Test with coverage
make test coverage=true

# Run a specific test file within a sub-package
julia --project=lib/YaoBlocks -e 'include("test/runtests.jl")'

# Serve docs locally with live reload
make servedocs

# Clean build artifacts
make clean
```

The main `test/runtests.jl` runs doctests across all modules plus EasyBuild tests.

## Architecture

**Block system**: Quantum circuits are represented as trees of `AbstractBlock` nodes. Two main subtypes:
- `PrimitiveBlock` — single gates (X, Y, Z, H, Rx, Ry, Rz, etc.) in `lib/YaoBlocks/src/primitive/`
- `CompositeBlock` — containers (Chain, Kron, ControlBlock, PutBlock, etc.) in `lib/YaoBlocks/src/composite/`

**Registers**: `ArrayReg` (state vector), `BatchedArrayReg` (batched simulation), `DensityMatrix`. Defined in `lib/YaoArrayRegister/src/`.

**Key functions**: `apply!(register, block)` applies a gate, `mat(block)` gets its matrix, `expect(op, reg)` computes expectation values, `measure(reg)` performs measurement.

**Autodiff**: Reverse-mode differentiation for parametric circuits lives in `lib/YaoBlocks/src/autodiff/`.

**GPU support**: CuYao extension in `ext/CuYao/`, activated as a package extension when CUDA is loaded.

**EasyBuild**: High-level circuit constructors (variational circuits, QFT, etc.) in `src/EasyBuild/`.

## Releasing

New versions are released by opening an issue on QuantumBFS/Yao.jl#179 (the release tracking issue).

## CI

GitHub Actions runs tests for each sub-package independently on Julia stable (see `.github/workflows/CI.yml`). Coverage is uploaded to Codecov. The `.ci/run.jl` script orchestrates package development and testing in CI.
