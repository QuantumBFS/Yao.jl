using Documenter
using YaoArrayRegister

makedocs(
    modules = [YaoArrayRegister],
    doctest = true,
    clean = false,
    sitename = "YaoArrayRegister.jl",
    pages = ["index.md"],
)
