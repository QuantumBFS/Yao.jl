using Compose, ZXCalculus

function plot_compose(zxd::Union{ZXDiagram, ZXGraph}; scale = 2)
    zxd = copy(zxd)
    ZXCalculus.generate_layout!(zxd)
    vs = spiders(zxd)
    x_locs = zxd.layout.spider_col
    x_min = minimum(values(x_locs)) - 0.5
    x_max = maximum(values(x_locs)) + 0.5
    x_range = x_max - x_min
    y_locs = zxd.layout.spider_q
    y_min = minimum(values(y_locs)) - 0.5
    y_max = maximum(values(y_locs)) + 0.5
    y_range = y_max - y_min
    x_locs_normal = copy(x_locs)
    for (v, x) in x_locs_normal
        x_locs_normal[v] = (x - x_min) - 0.25
    end
    y_locs_normal = copy(y_locs)
    for (v, y) in y_locs_normal
        y_locs_normal[v] = (y - y_min) - 0.25
    end
    st = zxd.st
    ps = zxd.ps
    nodes = generate_nodes(vs, st, ps, 0.1cm, scale)
    edges = generate_edges(zxd, x_locs_normal, y_locs_normal, scale)
    ct_vs = context()
    for v in vs
        ct_v = (context(x_locs_normal[v]*scale*cm, 
                y_locs_normal[v]*scale*cm, 
                0.5*scale*cm, 
                0.5*scale*cm
            ),
            nodes[v],
        )
        ct_vs = compose(context(), ct_vs, ct_v)
    end
    set_default_graphic_size(x_range*scale*cm, y_range*scale*cm)
    return compose(context(), ct_vs, edges)
end

function generate_nodes(vs, st, ps, ftsize, scale)
    nodes = Dict()
    for v in vs
        if st[v] ∈ (ZXCalculus.SpiderType.In, ZXCalculus.SpiderType.Out)
            spider_shape = :circle
            spider_color = "gray"
            spider_text = "[$v]"
        elseif st[v] == ZXCalculus.SpiderType.H
            spider_shape = :box
            spider_color = "yellow"
            spider_text = "[$v]"
        elseif st[v] == ZXCalculus.SpiderType.X
            spider_shape = :circle
            spider_color = "red"
            spider_text = "[$v]" * (iszero(ps[v]) ? "" : "\n$(ps[v])")
        elseif st[v] == ZXCalculus.SpiderType.Z
            spider_shape = :circle
            spider_color = "green"
            spider_text = "[$v]" * (iszero(ps[v]) ? "" : "\n$(ps[v])")
        end
        nodes[v] = (context(),
            (context(), text(0.5, 0.5, spider_text, hcenter, vcenter), fontsize(ftsize*scale)),
            (context(), (spider_shape === :circle) ? circle() : rectangle(0.25, 0.25, 0.5, 0.5), 
            fill(spider_color), stroke("black"), linewidth(0.3*scale*mm)),
        )
    end
    return nodes
end

function generate_edges(zxd::ZXDiagram, x_locs_normal, y_locs_normal, scale)
    ct_edges = context()
    for me in ZXCalculus.edges(zxd.mg)
        x_center = (x_locs_normal[me.src]+x_locs_normal[me.dst]+0.5)/2*scale*cm
        y_center = (y_locs_normal[me.src]+y_locs_normal[me.dst]+0.5)/2*scale*cm
        theta = angle((x_locs_normal[me.dst]-x_locs_normal[me.src])+im*(y_locs_normal[me.dst]-y_locs_normal[me.src]))
        theta = rem(theta, pi, RoundDown)
        r = Rotation(theta, x_center, y_center)
        ct_edges = (context(), ct_edges,
            (context(), 
                text(x_center, 
                    y_center, 
                    ((me.mul > 1) ? "× $(me.mul)\n" : ""), 
                    hcenter, vcenter, r
                ), 
                fill("black"), fontsize(1.5mm*scale)
            ),
            (context(), 
                line([((x_locs_normal[me.src]+0.25)*scale*cm, (y_locs_normal[me.src]+0.25)*scale*cm), 
                ((x_locs_normal[me.dst]+0.25)*scale*cm, (y_locs_normal[me.dst]+0.25)*scale*cm)]), 
                stroke("gray"), linewidth(0.3*scale*mm),
            )
        )
    end
    return ct_edges
end
function generate_edges(zxg::ZXGraph, x_locs_normal, y_locs_normal, scale)
    ct_edges = context()
    for me in ZXCalculus.edges(zxg.mg)
        ct_edges = (context(), ct_edges,
            (context(), 
                line([((x_locs_normal[me.src]+0.25)*scale*cm, (y_locs_normal[me.src]+0.25)*scale*cm), 
                ((x_locs_normal[me.dst]+0.25)*scale*cm, (y_locs_normal[me.dst]+0.25)*scale*cm)]), 
                stroke(ZXCalculus.is_hadamard(zxg, me.src, me.dst) ? "blue" : "black"), 
                linewidth(0.3*scale*mm),
            )
        )
    end
    return ct_edges
end