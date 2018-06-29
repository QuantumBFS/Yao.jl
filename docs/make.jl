using Documenter
using Yao, Yao.Blocks, Yao.LuxurySparse, Yao.Intrinsics, Yao.Registers, Yao.Interfaces

# TODO: use Literate to process examples
# using Literate
# preprocess tutorial scripts

# make documents
makedocs(
    modules = [Yao, Yao.Blocks, Yao.LuxurySparse, Yao.Intrinsics, Yao.Registers, Yao.Interfaces],
    clean = false,
    format = :html,
    sitename = "Yao.jl",
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
            "man/yao.md",
            "man/interfaces.md",
            "man/registers.md",
            "man/blocks.md",
            "man/cache.md",
            "man/intrinsics.md",
            "man/luxurysparse.md",
            "man/boost.md",
        ],
        "Developer Documentation" => Any[
            "dev/extending-blocks.md"
            "dev/benchmark.md"
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
