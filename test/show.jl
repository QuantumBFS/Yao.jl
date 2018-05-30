using Compat.Test
using Yao

macro test_io(mime, obj, str)
    quote
        @test sprint((io, x)->show(io, $(esc(mime))(), x), $(esc(obj))) == $(esc(str))
    end
end

@testset "composite" begin
target_str = "Total: 4, DataType: Complex{Float64}\n\e[1m\e[36mkron\e[39m\e[22m\n├─ \e[1m\e[37m1\e[39m\e[22m=>X gate\n└─ \e[1m\e[37m3\e[39m\e[22m=>Y gate\n"
@test_io MIME"text/plain" kron(4, X, 3=>Y) target_str

target_str = """Total: 1, DataType: Complex{Float64}
\e[1m\e[34mchain\e[39m\e[22m
├─ X gate
└─ X gate
"""

@test_io MIME"text/plain" chain(X, X) target_str

target_str = "Total: 4, DataType: Complex{Float64}\n\e[1m\e[31mcontrol(\e[39m\e[22m\e[1m\e[31m1\e[39m\e[22m\e[1m\e[31m, \e[39m\e[22m\e[1m\e[31m2\e[39m\e[22m\e[1m\e[31m, \e[39m\e[22m\e[1m\e[31m3\e[39m\e[22m\e[1m\e[31m)\e[39m\e[22m\n└─ \e[1m\e[37m4\e[39m\e[22m=>X gate\n"
@test_io MIME"text/plain" control([1, 2, 3], X, 4) target_str

target_str = "Total: 4, DataType: Complex{Float64}\n\e[1m\e[36mroller\e[39m\e[22m\n├─ X gate\n├─ X gate\n├─ X gate\n└─ X gate\n"
@test_io MIME"text/plain" roll(4, X) target_str

end
