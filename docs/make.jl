using Pkg

# pkg"""
# add Documenter Literate
# """

using Documenter, Literate, QuAlgorithmZoo

const PATH = (
    tutorial = joinpath(@__DIR__, "src/tutorial"),
    examples = joinpath(@__DIR__, "..", "examples")
)

function process_literate_scripts(;excludes=["make.jl", "README.md"])
    TUTORIALS = []
    for (root, dirs, files) in walkdir(PATH.examples)
        for file in files
            file in excludes && continue
            filepath = joinpath(root, file)
            Literate.markdown(filepath, PATH.tutorial)

            filename, _ = splitext(file)
            mdfile = join([filename, ".md"])
            # TODO: use PATH.tutorial rather then manual path
            push!(TUTORIALS, relpath(joinpath("tutorial", mdfile)))
        end
    end
    TUTORIALS
end

const TUTORIALS = process_literate_scripts()

#-----------------------------------------------

makedocs(
    modules = [QuAlgorithmZoo],
    clean = false,
    format = :html,
    sitename = "Quantum Algorithm Zoo",
    linkcheck = !("skiplinks" in ARGS),
    analytics = "UA-89508993-1",
    pages = [
        "Home" => "index.md",
        "Tutorial" => TUTORIALS,
    ],
    html_prettyurls = !("local" in ARGS),
    html_canonical = "https://quantumbfs.github.io/QuAlgorithmZoo.jl/latest/",
)

deploydocs(
    repo = "github.com/QuantumBFS/QuAlgorithmZoo.jl.git",
    target = "build",
    julia = "1.0",
    deps = nothing,
    make = nothing,
)
