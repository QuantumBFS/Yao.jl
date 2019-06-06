# Benchmarks

Each component package of Yao has a benchmark test based on [PkgBenchmark](https://github.com/JuliaCI/PkgBenchmark.jl)

To run the benchmarks, simply type

```julia
using PkgBenchmark

benchmarkpkg("YaoArrayRegister")
benchmarkpkg("YaoBlocks")
```

You can also compare the benchmark between different commits and pull requests. Check the [documentation](https://juliaci.github.io/PkgBenchmark.jl/stable/index.html) of **PkgBenchmark** for more details.

## Benchmarks
