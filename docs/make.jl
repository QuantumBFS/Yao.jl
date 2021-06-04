using Documenter
using Yao
using Yao: YaoBlocks, YaoArrayRegister, YaoBase, YaoSym
using YaoBase: BitBasis
using YaoBlocks: AD
using YaoBlocks: Optimise
using Documenter.Writers.HTMLWriter
using Documenter.Utilities.DOM
using Documenter.Utilities.DOM: Tag, @tags
using DocumenterTools: Themes
#Venerable Inventor :)

# create the themes
for w in ("light", "dark")
    header = read(joinpath(@__DIR__, "src/assets/quantumbfs-style.scss"), String)
    theme = read(joinpath(@__DIR__, "src/assets/quantumbfs-$(w)defs.scss"), String)
    write(joinpath(@__DIR__, "src/assets/quantumbfs-$(w).scss"), header*"\n"*theme)
end
# compile the themes
Themes.compile(joinpath(@__DIR__, "src/assets/quantumbfs-light.scss"), joinpath(@__DIR__, "src/assets/themes/documenter-light.css"))
Themes.compile(joinpath(@__DIR__, "src/assets/quantumbfs-dark.scss"), joinpath(@__DIR__, "src/assets/themes/documenter-dark.css"))

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
            asset("https://raw.githubusercontent.com/QuantumBFS/QuantumBFS.github.io/master/_assets/favicon-dark.ico", class=:ico),
            asset("https://fonts.googleapis.com/css?family=Quicksand|Montserrat|Source+Code+Pro|Lora&display=swap", class=:css),
        ],
    ),
    doctest = ("doctest=true" in ARGS),
    clean = false,
    sitename = "Documentation | Yao",
    linkcheck = !("skiplinks" in ARGS),
    pages = PAGES,
)

deploydocs(repo = "github.com/QuantumBFS/Yao.jl.git", target = "build")
