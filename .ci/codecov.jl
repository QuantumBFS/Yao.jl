using Pkg

Pkg.activate("coveragetempenv", shared = true)

Pkg.add(PackageSpec(name = "CoverageTools"))

using CoverageTools

function main()
    help = """
    code coverage processing.

    codecov.jl <package>
    """

    root_directory = dirname(@__DIR__)

    if length(ARGS) == 0
        package_names = readdir(joinpath(root_directory, "lib"))
    else
        package_names = ARGS
    end
    dirs = map(package_names) do name
        return if name == "Yao"
            joinpath(root_directory, "src")
        else
            joinpath(root_directory, "lib", name, "src")
        end
    end
    pfs = mapreduce(process_folder, vcat, dirs)
    LCOV.writefile(joinpath(root_directory, "lcov.info"), pfs)
    return 0
end

main()
