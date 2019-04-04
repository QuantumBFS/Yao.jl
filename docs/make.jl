using Documenter
using Yao

const PAGES = [
    "Home" => "index.md",
    # "Tutorial" => Any[
    #     "tutorial/registers.md",
    #     "tutorial/blocks.md",
    #     "tutorial/bit_operations.md",
    # ],
    "Examples" => Any[
        "examples/GHZ.md",
        "examples/QFT.md",
        "examples/Grover.md",
        "examples/QCBM.md",
    ],
    "Manual" => Any[
        "man/base.md",
        "man/registers.md",
        "man/blocks.md",
    ],
    "Developer Guide" => Any[
        "dev/customize_blocks.md",
        "dev/benchmarking.md",
    ],
]

makedocs(
    modules = [BitBasis],
    format = Documenter.HTML(
        prettyurls = ("deploy" in ARGS),
        canonical = ("deploy" in ARGS) ? "https://quantumbfs.github.io/Yao.jl/latest/" : nothing,
        assets = ["assets/favicon.ico"],
        ),
    clean = false,
    sitename = "Yao.jl",
    linkcheck = !("skiplinks" in ARGS),
    pages = PAGES
)

deploydocs(
    repo = "github.com/QuantumBFS/Yao.jl.git",
    target = "build",
)
