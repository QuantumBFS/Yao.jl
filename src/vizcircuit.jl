using Viznet: canvas
import Viznet
using Compose: CurvePrimitive, Form
using Yao
using BitBasis

export CircuitStyles, CircuitGrid, circuit_canvas, vizcircuit, pt, cm, darktheme!, lighttheme!

module CircuitStyles
    using Compose
    import Viznet
    const r = Ref(0.2)
    const lw = Ref(1pt)
    const textsize = Ref(16pt)
    const paramtextsize = Ref(10pt)
    const fontfamily = Ref("monospace")
    const linecolor = Ref("#000000")
    const gate_bgcolor = Ref("transparent")
    const textcolor = Ref("#000000")
    const scale = Ref(1.0)

    # formats
    struct ComposeSVG end
    struct Tikz end

    # Context is gate dependent information
    Base.@kwdef struct Context
        hspace::Float64
        wspace::Float64
    end

    abstract type Gadget end
    struct Box{FT} <: Gadget
        height::FT
        width::FT
    end
    struct Cross <: Gadget end
    struct Dot <: Gadget end
    struct NDot <: Gadget end
    struct OPlus <: Gadget end
    struct MeasureBox <: Gadget end
    struct Text{FT} <: Gadget
        fontsize::FT
    end
    struct Line <: Gadget end
    get_width(::Cross) = 0.0
    get_width(::Dot) = r[]/3
    get_width(::NDot) = r[]/3
    get_width(::OPlus) = r[]*1.4
    boxsize(b::Gadget, params) = (w = get_width(b); (w, w))
    function boxsize(b::Box, params)
        hspace, wspace = params.hspace, params.wspace
        return b.width + wspace, b.height + hspace
    end
    function boxsize(::MeasureBox, params)
        return 2 * r[], 2 * r[]
    end

    function render(::ComposeSVG, b::Box, params)
        WIDTH, HEIGHT = boxsize(b, params)
        compose(context(), rectangle(-WIDTH/2, -HEIGHT/2, WIDTH, HEIGHT), fill(gate_bgcolor[]), stroke(linecolor[]), linewidth(lw[]))
    end

    #G() = compose(context(), rectangle(-r[], -r[], 2*r[], 2*r[]), fill(gate_bgcolor[]), stroke(linecolor[]), linewidth(lw[]))
    render(::ComposeSVG, d::Dot, params) = compose(context(), circle(0.0, 0.0, get_width(d)/2), fill(linecolor[]), linewidth(0))
    render(::ComposeSVG, d::NDot, params) = compose(context(), circle(0.0, 0.0, get_width(d)/2), fill(gate_bgcolor[]), stroke(linecolor[]), linewidth(lw[]))
    render(::ComposeSVG, d::Cross, params) = compose(context(), xgon(0.0, 0.0, r[], 4), fill(linecolor[]), linewidth(0))
    function render(::ComposeSVG, d::OPlus, params)
        w = get_width(d) / 2
        compose(context(),
                    (context(), circle(0.0, 0.0, w), stroke(linecolor[]), linewidth(lw[]), fill("transparent")),
                    (context(), polygon([(-w, 0.0), (w, 0.0)]), stroke(linecolor[]), linewidth(lw[])),
                    (context(), polygon([(0.0, -w), (0.0, w)]), stroke(linecolor[]), linewidth(lw[]))
               )
    end
    render(::ComposeSVG, ::MeasureBox, params) = compose(context(),
                        rectangle(-r[], -r[], 2*r[], 2*r[]), fill(gate_bgcolor[]), stroke(linecolor[]), linewidth(lw[]),
                        compose(context(), curve((-0.8*r[], 0.5*r[]), (-0.8*r[], -0.6*r[]), (0.8*r[], -0.6*r[]), (0.8*r[], 0.5*r[])), stroke(linecolor[]), linewidth(lw[])),
                        compose(context(), line([(0.0, 0.5*r[]), (0.7*r[], -0.4*r[])]), stroke(linecolor[]), linewidth(lw[])),
        begin
            ns = Viznet.nodestyle(:triangle, fill(linecolor[]); r=0.1*r[], θ=atan(0.7, 0.9))
            Viznet.inner_most_containers(ns) do c
                Viznet.update_locs!(c.form_children, [(0.7*r[], -0.4*r[])])
            end
            ns
        end
        )

    render(::ComposeSVG, ::Line, params) = compose(context(), line(), stroke(linecolor[]), linewidth(lw[]))
    render(::ComposeSVG, t::Text, params) = compose(context(), text(0.0, 0.0, "", hcenter, vcenter), fontsize(t.fontsize*scale[]), fill(textcolor[]), font(fontfamily[]))

    Base.@kwdef struct GateStyles
        g = Box(2*r[], 2*r[])
        c = Dot()
        x = Cross()
        nc = NDot()
        not = OPlus()
        measure = MeasureBox()

        # other styles
        line = Line()
        text = Text(textsize[])
        smalltext = Text(paramtextsize[])
    end
end

struct CircuitGrid
    backend
    frontier::Vector{Int}
    w_depth::Float64
    w_line::Float64
    gatestyles::CircuitStyles.GateStyles
end

nline(c::CircuitGrid) = length(c.frontier)
depth(c::CircuitGrid) = frontier(c, 1, nline(c))
Base.getindex(c::CircuitGrid, i, j) = (c.w_depth*i, c.w_line*j)
Base.typed_vcat(c::CircuitGrid, ij1, ij2) = (c[ij1...], c[ij2...])

function CircuitGrid(nline::Int; w_depth=1.0, w_line=1.0, gatestyles=CircuitStyles.GateStyles(), backend=CircuitStyles.ComposeSVG())
    CircuitGrid(backend, zeros(Int, nline), w_depth, w_line, gatestyles)
end

function frontier(c::CircuitGrid, args...)
    maximum(i->c.frontier[i], min(args..., nline(c)):max(args..., 1))
end

function _draw!(c::CircuitGrid, loc_brush_texts)
    isempty(loc_brush_texts) && return
    # a loc can be a integer, or a range
    loc_brush_texts = sort(loc_brush_texts, by=x->maximum(x[1]))
    locs = Iterators.flatten(getindex.(loc_brush_texts, 1)) |> collect

    # get the gate width and the circuit depth to draw
    boxwidths, boxheights = Float64[], Float64[]
    for (j, b, txt) in loc_brush_texts
        length(j) == 0 && continue
        wspace, fontsize = text_width_and_size(txt)
        hspace = (maximum(j)-minimum(j)) * c.w_line
        context = CircuitStyles.Context(; wspace=wspace,
                                        hspace=hspace)
        boxwidth, boxheight = CircuitStyles.boxsize(b, context)
        push!(boxwidths, boxwidth)
        push!(boxheights, boxheight)
    end
    max_width = maximum(boxwidths)
    ncolumn = max(1, ceil(Int, max_width/c.w_depth + 0.2))  # 0.1 is the minimum gap between two columns

    ipre = frontier(c, minimum(locs):maximum(locs)...)
    i = ipre + ncolumn/2
    local jpre
    for (k, ((j, b, txt), boxheight)) in enumerate(zip(loc_brush_texts, boxheights))
        length(j) == 0 && continue
        wspace, fontsize = text_width_and_size(txt)
        hspace = (maximum(j)-minimum(j)) * c.w_line
        jmid = (minimum(j)+maximum(j))/2
        context = CircuitStyles.Context(; wspace=wspace,
                                        hspace=hspace)
        CircuitStyles.render(c.backend, b, context) >> c[i, jmid]
        CircuitStyles.render(c.backend, CircuitStyles.Text(fontsize), context) >> (c[i, jmid], txt)
        # use line to connect blocks in the same gate
        if k!=1
            CircuitStyles.render(c.backend, c.gatestyles.line, context) >> c[(i, jmid-boxheight/2/c.w_line); (i, jpre)]
        end
        jpre = jmid + boxheight/2/c.w_line
    end

    #jmin, jmax = min(locs..., nline(c)), max(locs..., 1)
    # connect horizontal lines
    for (width, (j, b, txt)) in zip(boxwidths, loc_brush_texts)
        for jj in j
            CircuitStyles.render(CircuitStyles.ComposeSVG(), c.gatestyles.line, nothing) >> c[(c.frontier[jj], jj); (i-width/2/c.w_depth, jj)]
            CircuitStyles.render(CircuitStyles.ComposeSVG(), c.gatestyles.line, nothing) >> c[(i+width/2/c.w_depth, jj); (ipre+ncolumn, jj)]
            c.frontier[jj] = ipre + ncolumn
        end
    end
    for j in setdiff(minimum(locs):maximum(locs), locs)
        CircuitStyles.render(CircuitStyles.ComposeSVG(), c.gatestyles.line, nothing) >> c[(c.frontier[j], j); (ipre+ncolumn, j)]
        c.frontier[j] = ipre + ncolumn
    end
end

function text_width_and_size(text)
    W = maximum(x->textwidth(x), split(text, "\n"))
    fontsize = W > 3 ? CircuitStyles.paramtextsize[] : CircuitStyles.textsize[]
    # -2 because the gate has a default size
    width = max(W - 4, 0) * fontsize.value * 0.025  # mm to cm
    return width, fontsize
end

function initialize!(c::CircuitGrid; starting_texts, starting_offset)
    starting_texts !== nothing && for j=1:nline(c)
        CircuitStyles.render(c.backend, c.gatestyles.text, nothing) >> (c[starting_offset, j], string(starting_texts[j]))
    end
end

function finalize!(c::CircuitGrid; show_ending_bar, ending_offset, ending_texts)
    i = frontier(c, 1, nline(c))
    for j=1:nline(c)
        show_ending_bar && c.gatestyles.line >> c[(i, j-0.2); (i, j+0.2)]
        CircuitStyles.render(c.backend, c.gatestyles.line, nothing) >> c[(i, j); (c.frontier[j], j)]
        ending_texts !== nothing && c.gatestyles.text >> (c[i+ending_offset, j], string(ending_texts[j]))
    end
end

# elementary
function draw!(c::CircuitGrid, p::PrimitiveBlock, address, controls)
    bts = length(controls)>=1 ? get_cbrush_texts(c, p) : get_brush_texts(c, p)
    _draw!(c, [controls..., (getindex.(Ref(address), occupied_locs(p)), bts[1], bts[2])])
end
function draw!(c::CircuitGrid, p::Daggered{<:PrimitiveBlock}, address, controls)
    bts = length(controls)>=1 ? get_cbrush_texts(c, content(p)) : get_brush_texts(c, content(p))
    _draw!(c, [controls..., (getindex.(Ref(address), occupied_locs(p)), bts[1], bts[2]*"'")])
end

function draw!(c::CircuitGrid, p::Scale, address, controls)
    fp = YaoBlocks.factor(p)
    if !(abs(fp) ≈ 1)
        error("can not visualize non-phase factor.")
    end
    draw!(c, YaoBlocks.phase(angle(fp)), [first(address)], controls)
    draw!(c, p.content, address, controls)
end
# Special primitive gates
function draw!(c::CircuitGrid, ::I2Gate, address, controls)
    return
end
function draw!(c::CircuitGrid, ::IdentityGate, address, controls)
    return
end
function draw!(c::CircuitGrid, p::ConstGate.SWAPGate, address, controls)
    bts = [(c.gatestyles.x, ""), (c.gatestyles.x, "")]
    _draw!(c, [controls..., [(address[l], bt...) for (l, bt) in zip(occupied_locs(p), bts)]...])
end
function draw!(c::CircuitGrid, p::ConstGate.CNOTGate, address, controls)
    bts = [(c.gatestyles.c, ""), (c.gatestyles.x, "")]
    _draw!(c, [controls..., [(address[l], bt...) for (l, bt) in zip(occupied_locs(p), bts)]...])
end
function draw!(c::CircuitGrid, p::ConstGate.CZGate, address, controls)
    bts = [(c.gatestyles.c, ""), (c.gatestyles.c, "")]
    _draw!(c, [controls..., [(address[l], bt...) for (l, bt) in zip(occupied_locs(p), bts)]...])
end
function draw!(c::CircuitGrid, p::ConstGate.ToffoliGate, address, controls)
    bts = [(c.gatestyles.c, ""), (c.gatestyles.c, ""), (c.gatestyles.x, "")]
    _draw!(c, [controls..., [(address[l], bt...) for (l, bt) in zip(occupied_locs(p), bts)]...])
end

# composite
function draw!(c::CircuitGrid, p::ChainBlock, address, controls)
    draw!.(Ref(c), subblocks(p), Ref(address), Ref(controls))
end

function draw!(c::CircuitGrid, p::PutBlock, address, controls)
    locs = [address[i] for i in p.locs]
    draw!(c, p.content, locs, controls)
end

function draw!(c::CircuitGrid, m::YaoBlocks.Measure, address, controls)
    @assert length(controls) == 0
    if m.postprocess isa RemoveMeasured
        error("can not visualize post-processing: `RemoveMeasured`.")
    end
    if !(m.operator isa ComputationalBasis)
        error("can not visualize measure blocks for operators")
    end
    locs = m.locations isa AllLocs ? collect(1:nqudits(m)) : [address[i] for i in m.locations]
    for (i, loc) in enumerate(locs)
        _draw!(c, [(loc, c.gatestyles.measure, "")])
        if m.postprocess isa ResetTo
            val = readbit(m.postprocess.x, i)
            _draw!(c, [(loc, c.gatestyles.g, val == 1 ? "P₁" : "P₀")])
        end
    end
end

function draw!(c::CircuitGrid, cb::ControlBlock{GT,C}, address, controls) where {GT,C}
    ctrl_locs = [address[i] for i in cb.ctrl_locs]
    locs = [address[i] for i in cb.locs]
    mycontrols = [(loc, (bit == 1 ? c.gatestyles.c : c.gatestyles.nc), "") for (loc, bit)=zip(ctrl_locs, cb.ctrl_config)]
    draw!(c, cb.content, locs, [controls..., mycontrols...])
end

for B in [:LabelBlock, :GeneralMatrixBlock]
    @eval function draw!(c::CircuitGrid, cb::$B, address, controls)
        length(address) == 0 && return
        #is_continuous_chunk(address) || error("address not continuous in a block marked as continous.")
        _draw!(c, [controls..., (address, c.gatestyles.g, string(cb))])
    end
end
for GT in [:KronBlock, :RepeatedBlock, :CachedBlock, :Subroutine, :(YaoBlocks.AD.NoParams)]
    @eval function draw!(c::CircuitGrid, p::$GT, address, controls)
        draw!(c, YaoBlocks.Optimise.to_basictypes(p), address, controls)
    end
end
# function draw!(c::CircuitGrid, b::GeneralMatrixBlock{GT}, address, controls) where {GT}
#     length(address) == 0 && return
#     nline = maximum(address)-minimum(address)
#     g = CircuitStyles.MULTIGATE(nline*c.w_line, get_textwidth(b.tag))
#     _draw!(c, [controls..., (address, g, b.tag)])
# end

for (GATE, SYM) in [(:XGate, :Rx), (:YGate, :Ry), (:ZGate, :Rz)]
    @eval get_brush_texts(c, b::RotationGate{D,T,<:$GATE}) where {D,T} = (c.gatestyles.g, "$($(SYM))($(pretty_angle(b.theta)))")
end
get_brush_texts(c, b::EasyBuild.FSimGate) = (c.gatestyles.g, "FSim($(pretty_angle(b.theta)), $(pretty_angle(b.phi)))")
get_brush_texts(c, ::EasyBuild.SqrtWGate) = (c.gatestyles.g, "√W")
get_brush_texts(c, ::EasyBuild.SqrtXGate) = (c.gatestyles.g, "√X")
get_brush_texts(c, ::EasyBuild.SqrtYGate) = (c.gatestyles.g, "√Y")

pretty_angle(theta) = string(theta)
function pretty_angle(theta::AbstractFloat)
    c = ZXCalculus.continued_fraction(theta/π, 10)
    if c.den < 100
        res = if c.num == 1
            "π"
        elseif c.num==0
            "0"
        elseif c.num==-1
            "-π"
        else
            "$(c.num)π"
        end
        if c.den != 1
            res *= "/$(c.den)"
        end
        res
    else
        "$(round(theta; digits=2))"
    end
end

get_brush_texts(c, ::ConstGate.SdagGate) = (c.gatestyles.g, "S'")
get_brush_texts(c, ::ConstGate.TdagGate) = (c.gatestyles.g, "T'")
get_brush_texts(c, ::ConstGate.PuGate) = (c.gatestyles.g, "P+")
get_brush_texts(c, ::ConstGate.PdGate) = (c.gatestyles.g, "P-")
get_brush_texts(c, ::ConstGate.P0Gate) = (c.gatestyles.g, "P₀")
get_brush_texts(c, ::ConstGate.P1Gate) = (c.gatestyles.g, "P₁")
get_brush_texts(c, b::PrimitiveBlock) = (c.gatestyles.g, string(b))
get_brush_texts(c, b::TimeEvolution) = (c.gatestyles.g, string(b))
get_brush_texts(c, b::ShiftGate) = (c.gatestyles.g, "ϕ($(pretty_angle(b.theta)))")
get_brush_texts(c, b::PhaseGate) = (c.gatestyles.c, "    $(pretty_angle(b.theta))\n")
function get_brush_texts(c, b::T) where T<:ConstantGate
    namestr = string(T.name.name)
    if endswith(namestr, "Gate")
        namestr = namestr[1:end-4]
    end
    # Fix!
    (c.gatestyles.g, namestr)
end

get_cbrush_texts(c, b::PrimitiveBlock) = get_brush_texts(c, b)
get_cbrush_texts(c, ::XGate) = (c.gatestyles.not, "")
get_cbrush_texts(c, ::ZGate) = (c.gatestyles.c, "")

# front end
plot(blk::AbstractBlock; kwargs...) = vizcircuit(blk; kwargs...)
function vizcircuit(blk::AbstractBlock; w_depth=0.85, w_line=0.75, scale=1.0, show_ending_bar=false, starting_texts=nothing, starting_offset=-0.3, ending_texts=nothing, ending_offset=0.3, graphsize=1.0, gatestyles=CircuitStyles.GateStyles(), backend=CircuitStyles.ComposeSVG())
    CircuitStyles.scale[] = scale
    img = circuit_canvas(nqudits(blk); w_depth, w_line, show_ending_bar, starting_texts, starting_offset, ending_texts, ending_offset, graphsize, gatestyles, backend) do c
        blk >> c
    end
    CircuitStyles.scale[] = 1.0
    return img |> rescale(scale)
end

function circuit_canvas(f, nline::Int; backend=CircuitStyles.ComposeSVG(), w_depth=0.85, w_line=0.75, show_ending_bar=false, starting_texts=nothing, starting_offset=-0.3, ending_texts=nothing, ending_offset=0.3, graphsize=1.0, gatestyles=CircuitStyles.GateStyles())
    c = CircuitGrid(nline; w_depth, w_line, gatestyles, backend)
    Viznet.empty_cache!()
    initialize!(c; starting_texts, starting_offset)
    f(c)
    finalize!(c; show_ending_bar, ending_texts, ending_offset)
    # flush!
    g = compose(context(),
        Viznet.flush!(Viznet.TEXT_CACHE)...,
        Viznet.flush!(Viznet.EDGE_CACHE)...,
        Viznet.flush!(Viznet.NODE_CACHE)...,
        )
    a, b = (depth(c)+1)*w_depth, nline*w_line
    Compose.set_default_graphic_size(a*2.5*graphsize*cm, b*2.5*graphsize*cm)
    compose(context(0.5/a, -0.5/b, 1/a, 1/b), g)
end

Base.:>>(blk::AbstractBlock, c::CircuitGrid) = draw!(c, blk, collect(1:nqudits(blk)), [])
Base.:>>(blk::Function, c::CircuitGrid) = blk(nline(c)) >> c

function rescale(factor)
    a, b = Compose.default_graphic_width, Compose.default_graphic_height
    Compose.set_default_graphic_size(a*factor, b*factor)
    graph -> compose(context(), graph)
end

vizcircuit(; kwargs...) = c->vizcircuit(c; kwargs...)

function darktheme!()
    const CircuitStyles.linecolor[] = "#FFFFFF"
    const CircuitStyles.textcolor[] = "#FFFFFF"
end

function lighttheme!()
    const CircuitStyles.linecolor[] = "#000000"
    const CircuitStyles.textcolor[] = "#000000"
end
