using Documenter
using YaoArrayRegister, YaoBlocks, YaoSym

makedocs(
    modules = [YaoSym],
    doctest = true,
    clean = false,
    sitename = "YaoSym.jl",
    pages = ["index.md"],
)
