using Documenter, Weave
using Yao, YaoBlocks, YaoArrayRegister, YaoBase, BitBasis, YaoSym

# Preprocess weave

# const Examples = ["GHZ", "QFT", "Grover", "QCBM"]
const Examples = ["GHZ", "QFT", "QCBM", "ErrorCorrection"]

for each in Examples
    file_path = joinpath(@__DIR__, "src", "examples", join([each, ".jmd"]))
    @info "expanding $file_path to markdown"
    weave(file_path)
end

const PAGES = [
    "Home" => "index.md",
    "Examples" => map(x->joinpath("examples", x * ".md"), Examples),
    "Manual" => Any[
        "man/array_registers.md",
        "man/blocks.md",
        "man/base.md",
        "man/registers.md",
        "man/bitbasis.md",
        "man/extending_blocks.md",
        "man/benchmarks.md",
        "man/symbolic.md",
        ],
]

makedocs(
    modules = [Yao, YaoBase, YaoArrayRegister, YaoBlocks, YaoSym, BitBasis],
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
