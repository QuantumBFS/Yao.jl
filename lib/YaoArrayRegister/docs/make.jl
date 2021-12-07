using Documenter
using YaoArrayRegister, YaoBase

makedocs(
    modules = [YaoArrayRegister],
    doctest = true,
    clean = false,
    sitename = "YaoArrayRegister.jl",
    pages = ["index.md"],
)
