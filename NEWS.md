# Yao v0.6.0 Release Notes

## New Features

- Symbolic Computation Support via [SymEngine](https://github.com/symengine/SymEngine.jl).
- automatic differentiation support with reversibility based optimization
- better CUDA performance in [CuYao](https://github.com/QuantumBFS/CuYao.jl)
- unitary channel support in [YaoBlocks#101](https://github.com/QuantumBFS/YaoBlocks.jl/pull/101)
- better `measure` with operators in [YaoBlocks#100](https://github.com/QuantumBFS/YaoBlocks.jl/pull/100)
- **yao script** a mark up language for quantum circuit in [YaoBlocks#92](https://github.com/QuantumBFS/YaoBlocks.jl/pull/92)
- new fidelity grad and operator fidelity grad. [YaoBlocks#109](https://github.com/QuantumBFS/YaoBlocks.jl/pull/109) ([GiggleLiu](https://github.com/GiggleLiu))

## Documentation Improvements
- new website! [yaoquantum.org](http://yaoquantum.org/)
- new tutorial! [tutorials.yaoquantum.org](http://tutorials.yaoquantum.org/dev/)
- new benchmark! [yaoquantum.org/benchmark](https://yaoquantum.org/benchmark)

## Core component package changes
### YaoBase changes

- generic batch kron (#18) ([Roger-luo](https://github.com/Roger-luo))
- make batched kron more general (#16) ([GiggleLiu](https://github.com/GiggleLiu))
- Fix measure dispatch (#22) ([GiggleLiu](https://github.com/GiggleLiu))
- fix measure (#20) ([GiggleLiu](https://github.com/GiggleLiu))
- add curried version of partial\_tr (#19) ([Roger-luo](https://github.com/Roger-luo))

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
- Fix measure dispatch (#42) ([GiggleLiu](https://github.com/GiggleLiu))
- Fix collapseto (#40) ([GiggleLiu](https://github.com/GiggleLiu))
- Fix transpose copy (#39) ([GiggleLiu](https://github.com/GiggleLiu))
- Val\(:H\) instruct (#37) ([GiggleLiu](https://github.com/GiggleLiu))


### YaoBlocks changes
- Fix rotation (#93) ([Roger-luo](https://github.com/Roger-luo))
- fix repeat dispatch (#88) ([GiggleLiu](https://github.com/GiggleLiu))
- fix a typo (#85) ([GiggleLiu](https://github.com/GiggleLiu))
- fix measure, symad (#84) ([GiggleLiu](https://github.com/GiggleLiu))
- fix repeat performance issue (#83) ([Roger-luo](https://github.com/Roger-luo))
- add Cz gate (#82) ([Roger-luo](https://github.com/Roger-luo))
- run formatter (#65) ([Roger-luo](https://github.com/Roger-luo))
- fix put\(chain...\) backward (#80) ([GiggleLiu](https://github.com/GiggleLiu))
- Fix sparsecheck on 1.3 (#77) ([Roger-luo](https://github.com/Roger-luo))
- make expect syntax consistent (#74) ([Roger-luo](https://github.com/Roger-luo))
- add more docs (#73) ([Roger-luo](https://github.com/Roger-luo))
- automatic differentiation (#71) ([GiggleLiu](https://github.com/GiggleLiu))
- loose type constraints to support symbolic computation (#69) ([Roger-luo](https://github.com/Roger-luo))
- Tree manipulation (#68) ([GiggleLiu](https://github.com/GiggleLiu))
- fix put\(chain...\) backward (#80) ([GiggleLiu](https://github.com/GiggleLiu))
- Noise (#104) ([Roger-luo](https://github.com/Roger-luo))
- add unitary channel (#101) ([Roger-luo](https://github.com/Roger-luo))
- better measure with op (#100) ([GiggleLiu](https://github.com/GiggleLiu))
- concentrate -\> subroutine (#96) ([Roger-luo](https://github.com/Roger-luo))
- New dump load (#92) ([GiggleLiu](https://github.com/GiggleLiu))
- transposed storage (#91) ([GiggleLiu](https://github.com/GiggleLiu))
- Dispatch Hadamard gate to specialized functions (#89) ([GiggleLiu](https://github.com/GiggleLiu))
- fix a typo (#85) ([GiggleLiu](https://github.com/GiggleLiu))
- add support to pair in chain (#72) ([Roger-luo](https://github.com/Roger-luo))

## External dependencies

### LuxurySparse

- fix 1.3 compat (#25) ([Roger-luo](https://github.com/Roger-luo))
- fix https://github.com/QuantumBFS/Yao.jl/issues/201 (#24) ([Roger-luo](https://github.com/Roger-luo))
- add randn! and rand! and zero (#23) ([GiggleLiu](https://github.com/GiggleLiu))
- fix-nightly-ambiguity-error (#22) ([GiggleLiu](https://github.com/GiggleLiu))
- fix-diag to sparse conversion (#21) ([GiggleLiu](https://github.com/GiggleLiu))
