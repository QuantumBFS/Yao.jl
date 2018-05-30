using Documenter, Yao

makedocs(
    modules = [Yao],
    clean = false,
    format = :html,
    sitename = "Yao",
    linkcheck = !("skiplinks" in ARGS),
    analytics = "UA-89508993-1",
    pages = [
        "Home" => "index.md",
        "Tutorial" => Any[
            "tutorial/GHZ.md",
            "tutorial/QFT.md",
            "tutorial/QCBM.md",
        ],
        "Manual" => Any[
            "man/blocks.md",
            "man/cache.md",
            "man/functional.md",
        ],
        "Developer Documentation" => Any[
            "dev/block.md",
            "dev/register.md",
            "dev/cache.md",
            "dev/visualization.md",
            "dev/unittest.md",
            "dev/APIs.md",
        ],
        "Theoretical Notes" => Any[
            "theo/register.md",
            "theo/rotation.md",
            "theo/grover.md",
            "theo/blocks.md",
        ],
    ],
    html_prettyurls = !("local" in ARGS),
    html_canonical = "https://quantumbfs.github.io/Yao.jl/latest/",
)

deploydocs(
    repo = "github.com/QuantumBFS/Yao.jl.git",
    target = "build",
    julia = "0.6",
    deps = nothing,
    make = nothing,
)
