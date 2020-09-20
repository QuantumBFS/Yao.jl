using Test, YaoPlots
using ZXCalculus, Multigraphs

@testset "zx plot" begin
    g = Multigraph(6)
    for e in [[1,3],[2,3],[3,4],[4,5],[4,6]]
        add_edge!(g, e)
    end
    ps = [0, 0, 0//1, 2//1, 0, 0]
    v_t = [SpiderType.In, SpiderType.Out, SpiderType.X, SpiderType.Z, SpiderType.Out, SpiderType.In]
    zxd = ZXDiagram(g, v_t, ps)
    plot(zxd)
    replace!(Rule{:b}(), zxd)
    plt = plot(zxd)
    @test plt !== nothing
end
