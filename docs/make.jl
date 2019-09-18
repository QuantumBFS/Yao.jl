using Pkg

pkg"""
add Documenter Literate Plots Yao
"""

using Documenter, Literate, QuAlgorithmZoo

const Examples = ["Grover", "VQE", "Shor"]

const PATH = (
    tutorial = joinpath(@__DIR__, "src/tutorial"),
    examples = joinpath(@__DIR__, "..", "examples")
)

function process_literate_scripts()
    TUTORIALS = []
    for token in Examples
        file = "$token.jl"
        filepath = joinpath(PATH.examples, token, file)
        Literate.markdown(filepath, PATH.tutorial)

        filename, _ = splitext(file)
        mdfile = join([filename, ".md"])
        # TODO: use PATH.tutorial rather then manual path
        push!(TUTORIALS, relpath(joinpath("tutorial", mdfile)))
    end
    TUTORIALS
end

#-----------------------------------------------

function generate(islocal::Bool="local" in ARGS)
    makedocs(
        modules = [QuAlgorithmZoo],
        clean = false,
        format = :html,
        sitename = "Quantum Algorithm Zoo",
        linkcheck = !("skiplinks" in ARGS),
        analytics = "UA-89508993-1",
        pages = [
            "Home" => "index.md",
            "Algorithms" => process_literate_scripts(),
            "Manual" => Any[
                "man/zoo.md",
            ],
        ],
        html_prettyurls = !islocal,
        html_canonical = "https://quantumbfs.github.io/QuAlgorithmZoo.jl/latest/",
    )

    deploydocs(
        repo = "github.com/QuantumBFS/QuAlgorithmZoo.jl.git",
        target = "build",
        julia = "1.0",
        deps = nothing,
        make = nothing,
    )
end

generate(true)
