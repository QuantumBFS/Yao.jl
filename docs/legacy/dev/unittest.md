# Unit Test

We use `Julia`'s stdlib `Test` for unit test. This document is about how to creat new test cases. And what should be test.

## Create new test case

## How to check test coverage

*Step 1*:  Navigate to your test directory, and start julia like this:

```sh
julia --code-coverage=user
```

*Step 2*: Run your tests (e.g., include("runtests.jl")) and quit Julia.

*Step 3*: Navigate to the top-level directory of your package, restart Julia (with no special flags) and analyze your code coverage:

```julia
using Coverage
# defaults to src/; alternatively, supply the folder name as argument
coverage = process_folder()
# Get total coverage for all Julia files
covered_lines, total_lines = get_summary(coverage)
# Or process a single file
@show get_summary(process_file("src/MyPkg.jl"))
```

check [Coverage.jl](https://github.com/JuliaCI/Coverage.jl) for more information.