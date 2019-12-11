# Benchmarks

## Benchmark Guard

To ensure some PR do not contain performance regression, we defined package
benchmarks with [PkgBenchmark](https://github.com/JuliaCI/PkgBenchmark.jl)
in each component package, you can run the benchmark suite and compare the
performance between different version and commits.

## Benchmark with Other Packages

We also provide benchmarks comparing to other packages, you can find a complete
benchmark results here: [quantum-benchmarks](https://github.com/Roger-luo/quantum-benchmarks/blob/master/RESULTS.md)

a glance of Yao's benchmark comparing to other packages:

![relative-gate](https://github.com/Roger-luo/quantum-benchmarks/raw/master/images/gates_relative.png)

![relative-circuit](https://github.com/Roger-luo/quantum-benchmarks/raw/master/images/pcircuit_relative.png)
