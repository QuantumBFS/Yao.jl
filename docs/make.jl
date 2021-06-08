using Documenter
using Yao
using Yao: YaoBlocks, YaoArrayRegister, YaoBase, YaoSym
using YaoBase: BitBasis
using YaoBlocks: AD
using YaoBlocks: Optimise
using Documenter.Writers.HTMLWriter
using Documenter.Utilities.DOM
using Documenter.Utilities.DOM: Tag, @tags
#Venerable Inventor :)

download("yaoquantum.org/assets/logo-light.png", "docs/src/assets/logo.png")

const PAGES = [
    "Home" => "index.md",
    "Manual" => Any[
        "man/array_registers.md",
        "man/symbolic.md",
        "man/blocks.md",
        "man/automatic_differentiation.md",
        "man/simplification.md",
        "man/base.md",
        "man/registers.md",
        "man/bitbasis.md",
        "man/extending_blocks.md",
    ],
    "Benchmark" => "benchmarks.md",
    "Developer Notes" => "dev/index.md",
]

makedocs(
    modules = [Yao, YaoBase, YaoArrayRegister, YaoBlocks, BitBasis, YaoSym, AD, Optimise],
    format = Documenter.HTML(
        prettyurls = ("deploy" in ARGS),
        canonical = ("deploy" in ARGS) ? "https://docs.yaoquantum.org/" : nothing,
        assets = [
            "assets/themes/indigo.css",
            asset("https://raw.githubusercontent.com/QuantumBFS/QuantumBFS.github.io/master/_assets/favicon-dark.ico", class=:ico),
        ],
    ),
    doctest = ("doctest=true" in ARGS),
    clean = false,
    sitename = "Documentation | Yao",
    linkcheck = !("skiplinks" in ARGS),
    pages = PAGES,
)

deploydocs(repo = "github.com/QuantumBFS/Yao.jl.git", target = "build")
