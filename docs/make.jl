using Documenter, QuCircuit

makedocs(
    modules = [QuCircuit],
    clean = false,
    format = :html,
    sitename = "Quantum Circuit Simulation for Julia",
    linkcheck = !("skiplinks" in ARGS),
    analytics = "UA-89508993-1",
    pages = [
        "Home" => "index.md",
        "Developer Documentation" => Any[
            "dev/block.md",
            "dev/register.md",
            "dev/cache.md",
            "dev/visualization.md",
            "dev/unittest.md",
        ],
        "Theoretical Notes" => Any[
            "theo/register.md",
            "theo/rotation.md",
            "theo/grover.md",
            "theo/blocks.md",
        ],
    ],
    html_prettyurls = !("local" in ARGS),
    html_canonical = "https://quantumbfs.github.io/QuCircuit.jl/latest/",
)

deploydocs(
    repo = "github.com/QuantumBFS/QuCircuit.jl.git",
    target = "build",
    julia = "0.6",
    deps = nothing,
    make = nothing,
)
