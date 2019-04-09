using Documenter, Weave
using Yao, YaoBlocks, YaoArrayRegister, YaoBase

# Preprocess weave

# const Examples = ["GHZ", "QFT", "Grover", "QCBM"]
const Examples = ["GHZ"]

for each in Examples
    weave(joinpath(@__DIR__, "src", "examples", join([each, ".jmd"])))
end

const PAGES = [
    "Home" => "index.md",
    # "Tutorial" => Any[
    #     "tutorial/registers.md",
    #     "tutorial/blocks.md",
    #     "tutorial/bit_operations.md",
    # ],
    "Examples" => map(x->joinpath("examples", x * ".md"), Examples),
    "Manual" => Any[
        "man/array_registers.md",
        "man/blocks.md",
        "man/base.md",
        "man/registers.md",
        "man/extending_blocks.md",
        ],
    # "Developer Guide" => Any[
    #     "dev/customize_blocks.md",
    #     "dev/benchmarking.md",
    # ],
]

makedocs(
    modules = [Yao, YaoBase, YaoArrayRegister, YaoBlocks],
    format = Documenter.HTML(
        prettyurls = ("deploy" in ARGS),
        canonical = ("deploy" in ARGS) ? "https://quantumbfs.github.io/Yao.jl/latest/" : nothing,
        assets = ["assets/favicon.ico"],
        ),
    doctest = ("doctest=true" in ARGS),
    clean = false,
    sitename = "Yao.jl",
    linkcheck = !("skiplinks" in ARGS),
    pages = PAGES
)

deploydocs(
    repo = "github.com/QuantumBFS/Yao.jl.git",
    target = "build",
)
