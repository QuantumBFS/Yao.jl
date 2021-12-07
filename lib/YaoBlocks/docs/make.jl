using Documenter
using YaoArrayRegister, YaoBase, YaoBlocks

makedocs(
    modules = [YaoBlocks],
    doctest = true,
    clean = false,
    sitename = "YaoBlocks.jl",
    pages = ["index.md"],
)
