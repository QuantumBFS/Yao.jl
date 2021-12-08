using DataFrames, Vega, ZXCalculus
export plot_vega

function spider_type_string(st1)
    st1 == SpiderType.X && return "X"
    st1 == SpiderType.Z && return "Z"
    st1 == SpiderType.H && return "H"
    st1 == SpiderType.Out && return "Out"
    st1 == SpiderType.In && return "In"
end

function generate_d_spiders(vs, st, ps, x_locs_normal, y_locs_normal)
    return DataFrame(
        id = [v for v in vs],
        x = [x_locs_normal[v] for v in vs],
        y = [y_locs_normal[v] for v in vs],
        spider_type = [spider_type_string(st[v]) for v in vs],
        phase = [iszero(ps[v]) ? "" : "$(ps[v])" for v in vs]
    )
end

function generate_d_edges(zxd::ZXDiagram)
    s = Int[]
    d = Int[]
    isH = Bool[]
    for e in ZXCalculus.edges(zxd.mg)
        push!(s, ZXCalculus.src(e))
        push!(d, ZXCalculus.dst(e))
        push!(isH, false)
    end
    return DataFrame(src = s, dst = d, isHadamard = isH)
end
function generate_d_edges(zxd::ZXGraph)
    s = Int[]
    d = Int[]
    isH = Bool[]
    for e in ZXCalculus.edges(zxd.mg)
        push!(s, ZXCalculus.src(e))
        push!(d, ZXCalculus.dst(e))
        push!(isH, ZXCalculus.is_hadamard(zxd, ZXCalculus.src(e), ZXCalculus.dst(e)))
    end
    return DataFrame(src = s, dst = d, isHadamard = isH)
end

function plot_vega(zxd::Union{ZXDiagram, ZXGraph}; scale = 2)
    lattice_unit = 50 * scale
    zxd = copy(zxd)
    ZXCalculus.generate_layout!(zxd)
    vs = spiders(zxd)
    x_locs = zxd.layout.spider_col
    x_min = minimum(values(x_locs))
    x_max = maximum(values(x_locs))
    x_range = (x_max - x_min) * lattice_unit
    y_locs = zxd.layout.spider_q
    y_min = minimum(values(y_locs))
    y_max = maximum(values(y_locs))
    y_range = (y_max - y_min) * lattice_unit
    x_locs_normal = copy(x_locs)
    for (k, v) in x_locs_normal
        x_locs_normal[k] = v * lattice_unit
    end
    y_locs_normal = copy(y_locs)
    for (k, v) in y_locs_normal
        y_locs_normal[k] = v * lattice_unit
    end
    
    st = zxd.st
    ps = zxd.ps
    d_spiders = generate_d_spiders(vs, st, ps, x_locs_normal, y_locs_normal)
    d_edges = generate_d_edges(zxd)

    spec = @vgplot(
        $schema = "https://vega.github.io/schema/vega/v5.json",
        height = y_range,
        width = x_range,
        padding = 0.5 * lattice_unit,
        marks = [
            {
                encode = {
                    update = {
                        strokeWidth = { signal = "edgeWidth" },
                        path = { field = "path" }
                    },
                    enter = {
                        stroke = { field = "color" }
                    }
                },
                from = { data = "edges" },
                type = "path"
            },
            {
                encode = {
                    update = {
                        stroke = { value = "black" },
                        x = { field = "x" },
                        strokeWidth = { signal = "strokeWidth" },
                        size = { signal = "spiderSize" },
                        y = { field = "y" }
                    },
                    enter = {
                        shape = { field = "shape" },
                        fill = { field = "color" }
                    }
                },
                from = { data = "spiders" },
                type = "symbol"
            },
            {
                encode = {
                    update = {
                        align = { value = "center" },
                        x = { field = "x" },
                        ne = { value = "top" },
                        opacity = { signal = "showIds" },
                        y = { field = "y" },
                        fontSize = { value = 6*lattice_unit/50 },
                        dy = { value = 18*lattice_unit/50 }
                    },
                    enter = {
                        fill = { value = "lightgray" },
                        text = { field = "id" }
                    }
                },
                from = { data = "spiders" },
                type = "text"
            },
            {
                encode = {
                    update = {
                        align = { value = "center" },
                        x = { field = "x" },
                        dy = { value = lattice_unit/50 },
                        baseline = { value = "middle" },
                        opacity = { signal = "showPhases" },
                        fontSize = { value = 6*lattice_unit/50 },
                        y = { field = "y" }
                    },
                    enter = {
                        fill = { value = "lightgray" },
                        text = { field = "phase" }
                    }
                },
                from = { data = "spiders" },
                type = "text"
            }
        ],
        data = [
            {
                name = "spiders",
                values = d_spiders,
                on = [
                    {
                        modify = "whichSymbol",
                        values = "newLoc && {x: newLoc.x, y: newLoc.y}",
                        trigger = "newLoc"
                    }
                ],
                transform = [
                    {
                        as = "shape",
                        expr = "datum.spider_type === 'Z' ? 'circle' : (datum.spider_type === 'X' ? 'circle' : (datum.spider_type === 'H' ? 'square' : 'circle'))",
                        type = "formula"
                    },
                    {
                        as = "color",
                        expr = "datum.spider_type === 'Z' ? '#389826' : (datum.spider_type === 'X' ? '#CB3C33' : (datum.spider_type === 'H' ? 'yellow' : '#9558B2'))",
                        type = "formula"
                    }
                ]
            },
            {
                name = "edges",
                values = d_edges,
                transform = [
                    {
                        key = "id",
                        fields = [
                            "src",
                            "dst"
                        ],
                        as = [
                            "source",
                            "target"
                        ],
                        from = "spiders",
                        type = "lookup"
                    },
                    {
                        targetX = "target.x",
                        shape = {
                            signal = "shape"
                        },
                        sourceX = "source.x",
                        targetY = "target.y",
                        type = "linkpath",
                        sourceY = "source.y",
                        orient = {
                            signal = "orient"
                        }
                    },
                    {
                        as = "color",
                        expr = "datum.isHadamard ? '#4063D8' : 'black'",
                        type = "formula"
                    }
                ]
            }
        ],
        signals = [
            {
                name = "showIds",
                bind = { input = "checkbox" },
                value = true
            },
            {
                name = "showPhases",
                bind = { input = "checkbox" },
                value = true
            },
            {
                name = "spiderSize",
                bind = {
                    step = lattice_unit/5,
                    max = 40*lattice_unit,
                    min = 2*lattice_unit,
                    input = "range"
                },
                value = 20*lattice_unit
            },
            {
                name = "strokeWidth",
                bind = {
                    step = 0.001*lattice_unit,
                    max = 3*lattice_unit/50,
                    min = 0,
                    input = "range"
                },
                value = 1.5*lattice_unit/50
            },
            {
                name = "edgeWidth",
                bind = {
                    step = 0.001*lattice_unit,
                    max = 3*lattice_unit/50,
                    min = 0.002*lattice_unit,
                    input = "range"
                },
                value = 1.5*lattice_unit/50
            },
            {
                name = "orient",
                bind = {
                    options = [
                        "horizontal",
                        "vertical"
                    ],
                    input = "select"
                },
                value = "horizontal"
            },
            {
                name = "shape",
                bind = {
                    options = [
                        "line",
                        "arc",
                        "curve",
                        "diagonal",
                        "orthogonal"
                    ],
                    input = "select"
                },
                value = "diagonal"
            },
            {
                name = "whichSymbol",
                on = [
                    {
                        events = "symbol:mousedown",
                        update = "datum"
                    },
                    {
                        events = "*:mouseup",
                        update = "{}"
                    }
                ],
                value = {}
            },
            {
                name = "newLoc",
                on = [
                    {
                        events = "symbol:mouseout[!event.buttons], window:mouseup",
                        update = "false"
                    },
                    {
                        events = "symbol:mouseover",
                        update = "{x: x(), y: y()}"
                    },
                    {
                        events = "[symbol:mousedown, window:mouseup] > window:mousemove!",
                        update = "{x: x(), y: y()}"
                    }
                ],
                value = false
            }
        ]
    )
    return spec
end
