using Documenter
using Yao, Yao.Blocks, Yao.Intrinsics, Yao.Registers, Yao.Interfaces

# preprocess tutorial scripts
using Literate, Pkg
tutorialpath = joinpath(dirname(pathof(Yao)), "../docs/src/tutorial")
for jlfile in ["RegisterBasics.jl", "BlockBasics.jl", "QCBM.jl"]
    Literate.markdown(joinpath(tutorialpath, jlfile), tutorialpath)
end

# make documents
makedocs(
    modules = [Yao, Yao.Blocks, Yao.Intrinsics, Yao.Registers, Yao.Interfaces],
    clean = false,
    format = :html,
    sitename = "Yao.jl",
    linkcheck = !("skiplinks" in ARGS),
    analytics = "UA-89508993-1",
    pages = [
        "Home" => "index.md",
        "Tutorial" => Any[
            "tutorial/RegisterBasics.md",
            "tutorial/BlockBasics.md",
            "tutorial/Diff.md",
        ],
        "Examples" => Any[
            "tutorial/GHZ.md",
            "tutorial/QFT.md",
            "tutorial/Grover.md",
            "tutorial/QCBM.md",
        ],
        "Manual" => Any[
            "man/yao.md",
            "man/interfaces.md",
            "man/registers.md",
            "man/blocks.md",
            "man/intrinsics.md",
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
    julia = "1.0",
    osname = "osx",
    deps = nothing,
    make = nothing,
)
