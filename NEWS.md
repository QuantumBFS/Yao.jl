# Yao v0.6.0 Release Notes

## New Features

- Symbolic Computation Support via [SymEngine](https://github.com/symengine/SymEngine.jl).
- automatic differentiation support with reversibility based optimization
- better CUDA performance in [CuYao](https://github.com/QuantumBFS/CuYao.jl)

## Core component package changes
### YaoBase changes

- generic batch kron (#18) ([Roger-luo](https://github.com/Roger-luo))
- make batched kron more general (#16) ([GiggleLiu](https://github.com/GiggleLiu))

### YaoArrayRegister changes

**Closed issues:**

- `instruct!` ambiguity error in julia1.2 (#28)
- The jldoctest fails (#26)

**Merged pull requests:**

- fix type error when ctrl is an empty tuple (#35) ([Roger-luo](https://github.com/Roger-luo))
- propagate inbounds (#34) ([Roger-luo](https://github.com/Roger-luo))
- Transposed storage (#30) ([GiggleLiu](https://github.com/GiggleLiu))
- fix return type (#33) ([Roger-luo](https://github.com/Roger-luo))
- fix partial bra \* ket (#32) ([Roger-luo](https://github.com/Roger-luo))
- add support for symbolic (#31) ([Roger-luo](https://github.com/Roger-luo))


### YaoBlocks changes
- Fix sparsecheck on 1.3 (#77) ([Roger-luo](https://github.com/Roger-luo))
- make expect syntax consistent (#74) ([Roger-luo](https://github.com/Roger-luo))
- add more docs (#73) ([Roger-luo](https://github.com/Roger-luo))
- automatic differentiation (#71) ([GiggleLiu](https://github.com/GiggleLiu))
- loose type constraints to support symbolic computation (#69) ([Roger-luo](https://github.com/Roger-luo))
- Tree manipulation (#68) ([GiggleLiu](https://github.com/GiggleLiu))
- fix put\(chain...\) backward (#80) ([GiggleLiu](https://github.com/GiggleLiu))

## External dependencies

### LuxurySparse

- fix 1.3 compat (#25) ([Roger-luo](https://github.com/Roger-luo))
- fix https://github.com/QuantumBFS/Yao.jl/issues/201 (#24) ([Roger-luo](https://github.com/Roger-luo))
- add randn! and rand! and zero (#23) ([GiggleLiu](https://github.com/GiggleLiu))
- fix-nightly-ambiguity-error (#22) ([GiggleLiu](https://github.com/GiggleLiu))
- fix-diag to sparse conversion (#21) ([GiggleLiu](https://github.com/GiggleLiu))


## Documentation Improvements
