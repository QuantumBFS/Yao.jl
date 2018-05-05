using Compat.Test

import QuCircuit: iscacheable, CacheElement

@testset "cache element" begin

    cache = CacheElement(Matrix{Complex128}, 3)
    @test iscacheable(cache, 3) == false
    @test iscacheable(cache, 4) == true

end