using Documenter
using DocThemeIndigo
using Literate
using Yao
using Yao: YaoBlocks, YaoArrayRegister, YaoSym, BitBasis, YaoAPI
using YaoBlocks: AD
using YaoBlocks: Optimise

function notebook_filter(str)
  re = r"(?<!`)``(?!`)"  # Two backquotes not preceded by nor followed by another
  replace(str, re => "\$")
end

attach_notebook_badge(root, name) = str->attach_notebook_badge(root, name, str)

function attach_notebook_badge(root, name, str)
    mybinder_badge_url = "https://mybinder.org/badge_logo.svg"
    nbviewer_badge_url = "https://img.shields.io/badge/show-nbviewer-579ACA.svg"
    download_badge_url = "https://img.shields.io/badge/download-project-orange"
    mybinder = "[![]($mybinder_badge_url)](@__BINDER_ROOT_URL__/generated/$root/$name/main.ipynb)"
    nbviewer = "[![]($nbviewer_badge_url)](@__NBVIEWER_ROOT_URL__/generated/$root/$name/main.ipynb)"
    download = "[![]($download_badge_url)](https://minhaskamal.github.io/DownGit/#/home?url=https://github.com/QuantumBFS/tutorials/tree/gh-pages/dev/generated/$root/$name)"

    markdown_only(x) = "#md # " * x
    return join(map(markdown_only, (mybinder, nbviewer, download)), "\n") * "\n\n" * str
end

function build_tutorial(root, name)
    generated_path = joinpath("generated", root, name)
    generated_abspath = joinpath(@__DIR__, "src", generated_path)
    source_dir = joinpath(@__DIR__, "src", root, name)
    source_path = joinpath(source_dir, "main.jl")
    Literate.markdown(source_path, generated_abspath; execute=true, name="index", preprocess = attach_notebook_badge(root, name))
    Literate.notebook(source_path, generated_abspath; execute=false, name="main", preprocess = notebook_filter)
    Literate.script(source_path, generated_abspath; execute=false, name="main")
    # copy other things
    for each in readdir(source_dir)
        if each != "main.jl"
            cp(joinpath(source_dir, each), joinpath(generated_abspath, each), force=true)
        end
    end
    return joinpath(generated_path, "index.md")
end

function build(root)
    tutorials = readdir(joinpath(@__DIR__, "src", root))
    pages = String[]
    for each in tutorials
        push!(pages, build_tutorial(root, each))
    end
    return pages
end

# download("yaoquantum.org/assets/logo-light.png", "docs/src/assets/logo.png")

const PAGES = [
    "Home" => "index.md",
    "Quick Start" => build("quick-start"),
    # TODO: fix the openfermion example, looks like
    # there is an API change in upstream
    # "Developer Guide" => build("developer-guide"),
    "Manual" => Any[
        "man/array_registers.md",
        "man/symbolic.md",
        "man/blocks.md",
        "man/automatic_differentiation.md",
        "man/simplification.md",
        "man/registers.md",
        "man/bitbasis.md",
        "man/extending_blocks.md",
    ],
    "Benchmark" => "benchmarks.md",
    "Developer Notes" => "dev/index.md",
]

indigo = DocThemeIndigo.install(Yao)

makedocs(
    modules = [Yao, YaoAPI, YaoArrayRegister, YaoBlocks, BitBasis, YaoSym, AD, Optimise],
    format = Documenter.HTML(
        prettyurls = ("deploy" in ARGS),
        canonical = ("deploy" in ARGS) ? "https://docs.yaoquantum.org/" : nothing,
        assets = [
            indigo,
            asset("https://yaoquantum.org/assets/favicon-light.ico", class = :ico),
        ],
    ),
    doctest = ("doctest=true" in ARGS),
    clean = false,
    sitename = "Documentation | Yao",
    linkcheck = !("skiplinks" in ARGS),
    pages = PAGES,
)


deploydocs(repo = "github.com/QuantumBFS/Yao.jl.git", target = "build")


# using LiveServer; servedocs(skip_dirs=["docs/src/assets", "docs/src/generated"])
