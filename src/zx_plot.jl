using ZXCalculus
using LightGraphs
using GraphPlot: gplot
using Colors
using ZXCalculus: qubit_loc
using Compose

export ZXplot

function Multigraph2Graph(mg::Multigraph)
    g = SimpleGraph(nv(mg))
    vs = vertices(mg)
    for me in edges(mg)
        add_edge!(g, searchsortedfirst(vs, src(me)), searchsortedfirst(vs, dst(me)))
    end
    # multiplicities = ["$(mul(mg, src(e), dst(e)))" for e in edges(g)]
    multiplicities = ["×$(mul(mg, vs[src(e)], vs[dst(e)]))" for e in edges(g)]
    for i = 1:length(multiplicities)
        if multiplicities[i] == "×1"
            multiplicities[i] = ""
        end
    end
    return g, multiplicities
end

ZX2Graph(zxd::ZXDiagram) = Multigraph2Graph(zxd.mg)
ZX2Graph(zxg::ZXGraph) = Multigraph2Graph(zxg.mg)

function et2color(et::String)
    et == "" && return colorant"black"
    et == "×2" && return colorant"blue"
end

function st2color(S::SpiderType.SType)
    S == SpiderType.Z && return colorant"green"
    S == SpiderType.X && return colorant"red"
    S == SpiderType.H && return colorant"yellow"
    S == SpiderType.In && return colorant"lightblue"
    S == SpiderType.Out && return colorant"gray"
end

ZX2nodefillc(zxd) = [st2color(zxd.st[v]) for v in vertices(zxd.mg)]

function ZX2nodelabel(zxd)
    nodelabel = String[]
    for v in vertices(zxd.mg)
        zxd.st[v] == SpiderType.Z && push!(nodelabel, "[$(v)]\n$(print_phase(zxd.ps[v]))")
        zxd.st[v] == SpiderType.X && push!(nodelabel, "[$(v)]\n$(print_phase(zxd.ps[v]))")
        zxd.st[v] == SpiderType.H && push!(nodelabel, "[$(v)]")
        zxd.st[v] == SpiderType.In && push!(nodelabel, "[$(v)]")
        zxd.st[v] == SpiderType.Out && push!(nodelabel, "[$(v)]")
    end
    return nodelabel
end

function print_phase(p)
    if typeof(p) <: Rational
        return "$(p.num)π/$(p.den)"
    else
        return "$p π"
    end
end

function layout2locs(zxd::ZXDiagram{T,P}) where {T,P}
    lo = zxd.layout
    vs = spiders(zxd)
    locs = Dict()
    nqubit = lo.nbits
    frontier_v = ones(T, nqubit)
    frontier_locs = ones(nqubit)

    while sum([frontier_v[i] <= length(lo.spider_seq[i]) for i = 1:nqubit]) > 0
        for q = 1:nqubit
            if frontier_v[q] <= length(lo.spider_seq[q])
                v = lo.spider_seq[q][frontier_v[q]]
                nb = neighbors(zxd, v)
                if length(nb) <= 2
                    locs[v] = (Float64(frontier_locs[q]), Float64(q))
                    frontier_locs[q] += 1
                    frontier_v[q] += 1
                else
                    v1 = nb[[qubit_loc(lo, u) != q for u in nb]][1]
                    if spider_type(zxd, v1) == SpiderType.H
                        v1 = setdiff(neighbors(zxd, v1), [v])[1]
                    end
                    if sum([findfirst(isequal(u), lo.spider_seq[qubit_loc(lo, u)]) != frontier_v[qubit_loc(lo, u)] for u in [v, v1]]) == 0
                        x = maximum(frontier_locs[min(qubit_loc(lo, v), qubit_loc(lo, v1)):max(qubit_loc(lo, v), qubit_loc(lo, v1))])
                        for u in [v, v1]
                            locs[u] = (Float64(x), Float64(qubit_loc(lo, u)))
                            frontier_v[qubit_loc(lo, u)] += 1
                        end
                        for q in min(qubit_loc(lo, v), qubit_loc(lo, v1)):max(qubit_loc(lo, v), qubit_loc(lo, v1))
                            frontier_locs[q] = x + 1
                        end
                    end
                end
            end
        end
    end
    for v in vs
        if !haskey(locs, v)
            v1, v2 = neighbors(zxd, v)
            x1, y1 = locs[v1]
            x2, y2 = locs[v2]
            locs[v] = ((x1+x2)/2, (y1+y2)/2)
        end
    end
    locs_x = [locs[v][1] for v in vs]
    locs_y = [locs[v][2] for v in vs]
    return locs_x, locs_y
end

function layout2locs(zxd::ZXGraph{T,P}) where {T,P}
    lo = zxd.layout
    vs = spiders(zxd)
    locs = Dict()
    nqubit = lo.nbits
    frontier_v = ones(T, nqubit)
    frontier_locs = ones(nqubit)
    phase_gadget_loc = 1.0

    for v in vs
        if qubit_loc(lo, v) != nothing
            y = qubit_loc(lo, v)
            x = findfirst(isequal(v), lo.spider_seq[y])
            locs[v] = (Float64(x), Float64(y))
        else
            locs[v] = nothing
        end
    end
    for v in vs
        if locs[v] == nothing
            nb = neighbors(zxd, v)
            if length(nb) == 1
                u = nb[1]
                locs[v] = (phase_gadget_loc, Float64(nqubit + 2))
                locs[u] = (phase_gadget_loc, Float64(nqubit + 1))
                phase_gadget_loc += 1
            end

            # v1, v2 = neighbors(zxd, v)
            # x1, y1 = locs[v1]
            # x2, y2 = locs[v2]
            # locs[v] = ((x1+x2)/2, (y1+y2)/2)
        end
    end
    println(locs)
    locs_x = [locs[v][1] for v in vs]
    locs_y = [locs[v][2] for v in vs]
    return locs_x, locs_y
end

function ZXplot(zxd::ZXDiagram; linetype = "straight")
    g, edgelabel = ZX2Graph(zxd)
    nodelabel = ZX2nodelabel(zxd)
    nodefillc = ZX2nodefillc(zxd)
    edgelabelc = colorant"black"
    if zxd.layout.nbits > 0
        locs_x, locs_y = layout2locs(zxd)
        size_x = maximum(locs_x) - minimum(locs_x)
        size_y = maximum(locs_y) - minimum(locs_y)
        set_default_graphic_size(3size_x*cm, 3size_y*cm)
        composition = gplot(g,
            locs_x, locs_y,
            nodelabel = nodelabel, edgelabel = edgelabel, edgelabelc = edgelabelc, nodefillc = nodefillc,
            linetype = linetype,
            NODESIZE = 1/(2size_x),
            # EDGELINEWIDTH = 8.0 / sqrt(nv(g))
        )
        # draw(SVG("test.svg", size_x*cm, size_y*cm), composition)
    else
        gplot(g,
            nodelabel = nodelabel, edgelabel = edgelabel, edgelabelc = edgelabelc, nodefillc = nodefillc,
            linetype = linetype,
            # NODESIZE = 0.35 / sqrt(nv(g)), EDGELINEWIDTH = 8.0 / sqrt(nv(g))
        )
    end
end
function ZXplot(zxd::ZXGraph; linetype = "straight")
    g, edge_types = ZX2Graph(zxd)

    nodelabel = ZX2nodelabel(zxd)
    nodefillc = ZX2nodefillc(zxd)
    edgestrokec = et2color.(edge_types)
    if zxd.layout.nbits > 0
        locs_x, locs_y = layout2locs(zxd)
        size_x = maximum(locs_x) - minimum(locs_x)
        size_y = maximum(locs_y) - minimum(locs_y)
        set_default_graphic_size(3size_x*cm, 3size_y*cm)
        gplot(g,
            locs_x, locs_y,
            nodelabel = nodelabel,
            edgestrokec = edgestrokec,
            nodefillc = nodefillc,
            linetype = linetype,
            NODESIZE = 1/(2size_x),
            # NODESIZE = 0.35 / sqrt(nv(g)), EDGELINEWIDTH = 8.0 / sqrt(nv(g))
            )
    else
        gplot(g,
            nodelabel = nodelabel,
            edgestrokec = edgestrokec,
            nodefillc = nodefillc,
            linetype = linetype,
            # NODESIZE = 0.35 / sqrt(nv(g)), EDGELINEWIDTH = 8.0 / sqrt(nv(g))
            )
    end
end
