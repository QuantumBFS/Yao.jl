using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.CacheServers
using Yao.Blocks

@testset "primitive" begin
empty!(:all)
g = cache(X, 4)
update_cache(g, 2) # do nothing
@test_throws KeyError pull(g)

update_cache(g, 5)
@test pull(g) ≈ mat(g)
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
@test pull(g[1]) ≈ mat(g[1])
@test_throws KeyError pull(g[2])

update_cache(g, 4)
@test pull(g[1]) ≈ mat(g[1])
@test pull(g[2]) ≈ mat(g[2])

end
