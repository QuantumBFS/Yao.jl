using Compat.Test
using Yao

@testset "primitive" begin
empty!(:all)
g = cache(X, 4)
update_cache(g, 2) # do nothing
@test_throws KeyError pull(g)

update_cache(g, 5)
@test pull(g) ≈ sparse(g)
end

@testset "composite" begin
empty!(:all)
g = chain(
    cache(phase(0.1), 2),
    cache(phase(0.2), 3),
)

update_cache(g, 2) # do nothing
@test_throws KeyError pull(g[1])
@test_throws KeyError pull(g[2])

update_cache(g, 3)
@test pull(g[1]) ≈ sparse(g[1])
@test_throws KeyError pull(g[2])

update_cache(g, 4)
@test pull(g[1]) ≈ sparse(g[1])
@test pull(g[2]) ≈ sparse(g[2])

end
