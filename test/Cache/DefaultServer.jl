using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao.CacheServers

@testset "default server" begin
    ds = DefaultServer(SparseMatrixCSC{ComplexF64, Int})
    g = kron(3, X(), phase(0.1), Rx(0.1))

    # cache recursively
    cache!(ds, g, unsigned(2))
    for i = 1:3
        cache!(ds, g[i], unsigned(2))
    end

    # update recursively
    push!(ds, g, sparse(mat(g)))

    for i=1:3
        push!(ds, g[i], sparse(mat(g[i])))
    end

    # pull
    pull(ds, g) == sparse(mat(g))
    for i=1:3
        @test pull(ds, g[i]) == sparse(mat(g[i]))
    end
end
