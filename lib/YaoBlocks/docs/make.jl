using Documenter
using YaoArrayRegister, YaoAPI, YaoBlocks

makedocs(
    modules = [YaoBlocks],
    doctest = true,
    clean = false,
    sitename = "YaoBlocks.jl",
    pages = ["index.md"],
)
