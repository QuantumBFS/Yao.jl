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

Click the image to check the interactive plot.

```@raw html
<div>
    <a href="https://plot.ly/~rogerluo.rl18/1/?share_key=nUtdrjZojW6kZEbO6JwnPW" target="_blank" title="Yao-ProjectQ-Benchmarks" style="display: block; text-align: center;"><img src="https://plot.ly/~rogerluo.rl18/1.png?share_key=nUtdrjZojW6kZEbO6JwnPW" alt="Yao-ProjectQ-Benchmarks" style="max-width: 100%;width: 1000px;"  width="1000" onerror="this.onerror=null;this.src='https://plot.ly/404.png';" /></a>
    <script data-plotly="rogerluo.rl18:1" sharekey-plotly="nUtdrjZojW6kZEbO6JwnPW" src="https://plot.ly/embed.js" async></script>
</div>
```
