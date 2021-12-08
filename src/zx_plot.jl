using ZXCalculus
using LightGraphs, Multigraphs
using GraphPlot: gplot
using Colors
using ZXCalculus: qubit_loc

function Multigraph2Graph(mg::Multigraph)
    g = SimpleGraph(nv(mg))
    vs = sort!(vertices(mg))
    for me in edges(mg)
        add_edge!(g, searchsortedfirst(vs, src(me)), searchsortedfirst(vs, dst(me)))
    end
    multiplicities = ["×$(mul(mg, vs[src(e)], vs[dst(e)]))" for e in edges(g)]
    for i = 1:length(multiplicities)
        if multiplicities[i] == "×1"
            multiplicities[i] = ""
        end
    end
    return g, multiplicities
end

ZX2Graph(zxd::ZXDiagram) = Multigraph2Graph(zxd.mg)
function ZX2Graph(zxg::ZXGraph)
    g = SimpleGraph(nv(zxg.mg))
    vs = sort!(vertices(zxg.mg))
    for me in edges(zxg.mg)
        add_edge!(g, searchsortedfirst(vs, src(me)), searchsortedfirst(vs, dst(me)))
    end
    # multiplicities = ["$(mul(mg, src(e), dst(e)))" for e in edges(g)]
    multiplicities = [ZXCalculus.is_hadamard(zxg, vs[src(e)], vs[dst(e)]) ? "×2" : "" for e in edges(g)]
    return g, multiplicities
end

function et2color(et::String)
    et == "" && return colorant"black"
    return colorant"blue"
end

function st2color(S::SpiderType.SType)
    S == SpiderType.Z && return colorant"green"
    S == SpiderType.X && return colorant"red"
    S == SpiderType.H && return colorant"yellow"
    S == SpiderType.In && return colorant"lightblue"
    S == SpiderType.Out && return colorant"gray"
end

ZX2nodefillc(zxd) = [st2color(zxd.st[v]) for v in sort!(vertices(zxd.mg))]

function ZX2nodelabel(zxd)
    nodelabel = String[]
    for v in sort!(vertices(zxd.mg))
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
    spider_seq = ZXCalculus.spider_sequence(zxd)
    vs = sort!(spiders(zxd))
    locs = Dict()
    nqubit = lo.nbits
    frontier_v = ones(T, nqubit)
    frontier_locs = ones(nqubit)

    while sum([frontier_v[i] <= length(spider_seq[i]) for i = 1:nqubit]) > 0
        for q = 1:nqubit
            if frontier_v[q] <= length(spider_seq[q])
                v = spider_seq[q][frontier_v[q]]
                nb = neighbors(zxd, v)
                if length(nb) <= 2
                    locs[v] = (Float64(frontier_locs[q]), Float64(q))
                    frontier_locs[q] += 1
                    frontier_v[q] += 1
                else
                    v1 = nb[[qubit_loc(zxd, u) != q for u in nb]][1]
                    if spider_type(zxd, v1) == SpiderType.H
                        v1 = setdiff(neighbors(zxd, v1), [v])[1]
                    end
                    if sum([findfirst(isequal(u), spider_seq[qubit_loc(zxd, u)]) != frontier_v[qubit_loc(zxd, u)] for u in [v, v1]]) == 0
                        x = maximum(frontier_locs[min(qubit_loc(zxd, v), qubit_loc(zxd, v1)):max(qubit_loc(zxd, v), qubit_loc(zxd, v1))])
                        for u in [v, v1]
                            locs[u] = (Float64(x), Float64(qubit_loc(zxd, u)))
                            frontier_v[qubit_loc(zxd, u)] += 1
                        end
                        for q in min(qubit_loc(zxd, v), qubit_loc(zxd, v1)):max(qubit_loc(zxd, v), qubit_loc(zxd, v1))
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

function layout2locs(zxg::ZXGraph{T,P}) where {T,P}
    lo = zxg.layout
    spider_seq = ZXCalculus.spider_sequence(zxg)
    vs = sort!(spiders(zxg))
    locs = Dict()
    nqubit = lo.nbits
    frontier_v = ones(T, nqubit)
    frontier_locs = ones(nqubit)
    phase_gadget_loc = 1.0

    for v in vs
        if qubit_loc(zxg, v) !== nothing
            y = qubit_loc(zxg, v)
            x = findfirst(isequal(v), spider_seq[y])
            locs[v] = (Float64(x), Float64(y))
        else
            locs[v] = nothing
        end
    end
    for v in vs
        if locs[v] === nothing
            nb = neighbors(zxg, v)
            if length(nb) == 1
                gads = [v]
                u = v
                w = setdiff(neighbors(zxg, u), gads)[1]
                while locs[w] === nothing
                    push!(gads, w)
                    u = w
                    w = setdiff(neighbors(zxg, u), gads)[1]
                end
                push!(gads, w)
                for j = 1:(length(gads) - 1)
                    locs[gads[length(gads)-j]] = (phase_gadget_loc, Float64(nqubit + j))
                end
                phase_gadget_loc += 1
            end
        end
    end
    for v in vs
        if locs[v] === nothing
            # println(v)
            locs[v] = (phase_gadget_loc, Float64(nqubit + 1))
            phase_gadget_loc += 1
        end
    end
    locs_x = [locs[v][1] for v in vs]
    locs_y = [locs[v][2] for v in vs]
    return locs_x, locs_y
end

function plot(zxd::ZXDiagram; size_x=nothing, size_y=nothing, kwargs...)
    g, edgelabel = ZX2Graph(zxd)
    nodelabel = ZX2nodelabel(zxd)
    nodefillc = ZX2nodefillc(zxd)
    edgelabelc = colorant"black"
    if zxd.layout.nbits > 0
        locs_x, locs_y = layout2locs(zxd)
        if size_x === nothing
            size_x = maximum(locs_x) - minimum(locs_x)
        end
        if size_y === nothing
            size_y = maximum(locs_y) - minimum(locs_y)
        end
        set_default_graphic_size(3size_x*cm, 3size_y*cm)
        composition = gplot(g,
            locs_x, locs_y;
            nodelabel = nodelabel, edgelabel = edgelabel, edgelabelc = edgelabelc, nodefillc = nodefillc,
            NODESIZE = 1/(2size_x),
            kwargs...
            # EDGELINEWIDTH = 8.0 / sqrt(nv(g))
        )
        # draw(SVG("test.svg", size_x*cm, size_y*cm), composition)
    else
        gplot(g;
            nodelabel = nodelabel, edgelabel = edgelabel, edgelabelc = edgelabelc, nodefillc = nodefillc,
            kwargs...
            # NODESIZE = 0.35 / sqrt(nv(g)), EDGELINEWIDTH = 8.0 / sqrt(nv(g))
        )
    end
end
function plot(zxd::ZXGraph; size_x=nothing, size_y=nothing, kwargs...)
    g, edge_types = ZX2Graph(zxd)

    nodelabel = ZX2nodelabel(zxd)
    nodefillc = ZX2nodefillc(zxd)
    edgestrokec = et2color.(edge_types)
    if zxd.layout.nbits > 0
        locs_x, locs_y = layout2locs(zxd)
        if size_x === nothing
            size_x = maximum(locs_x) - minimum(locs_x)
        end
        if size_y === nothing
            size_y = maximum(locs_y) - minimum(locs_y)
        end
        set_default_graphic_size(3size_x*cm, 3size_y*cm)
        gplot(g,
            locs_x, locs_y;
            nodelabel = nodelabel,
            edgestrokec = edgestrokec,
            nodefillc = nodefillc,
            NODESIZE = 1/(2size_x),
            kwargs...
            )
    else
        gplot(g;
            nodelabel = nodelabel,
            edgestrokec = edgestrokec,
            nodefillc = nodefillc,
            kwargs...
            )
    end
end
