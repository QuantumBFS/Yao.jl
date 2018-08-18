using Pkg

pkg"""
add Documenter Literate
"""

using Documenter, Literate, QuAlgorithmZoo

const TUTORIAL = joinpath(@__DIR__, "src/tutorial")
const EXAMPLES = joinpath(@__DIR__, "..", "examples")

for (root, dirs, files) in walkdir(EXAMPLES)
    for file in files
        println(joinpath(root, file))
    end
end

# Literate.markdown(EXAMPLES, TUTORIAL)
