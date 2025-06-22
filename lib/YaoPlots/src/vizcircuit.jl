"""
    CircuitStyles

A module to define the styles of the circuit visualization.
To change the styles, please modify the variables in this module, e.g.
```julia
julia> using YaoPlots

julia> YaoPlots.CircuitStyles.unit[] = 40
40
```

### Style variables
#### Sizes
* `unit` is the number of pixels in a unit.
* `r` is the size of nodes.
* `lw` is the line width.

#### Texts
* `textsize` is the text size.
* `paramtextsize` is the text size for longer texts.
* `fontfamily` is the font family.

#### Colors
* `linecolor` is the line color.
* `gate_bgcolor` is the gate background color.
* `textcolor` is the text color.
"""
module CircuitStyles
    using Luxor
    const unit = Ref(60)    # number of pixels in a unit
    const barrier_for_chain = Ref(false)
    const r = Ref(0.2)
    const lw = Ref(1.0)
    const textsize = Ref(16.0)
    const paramtextsize = Ref(10.0)
    const fontfamily = Ref("JuliaMono")
    #const fontfamily = Ref("Dejavu Sans")
    const linecolor = Ref("#000000")
    const gate_bgcolor = Ref("transparent")
    const textcolor = Ref("#000000")

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
    struct Phase <: Gadget
        text::String
    end
    struct Text{FT} <: Gadget
        fontsize::FT
    end
    struct Line <: Gadget end
    get_width(::Cross) = 0.0
    get_width(::Phase) = r[]/2.5
    get_width(::Dot) = r[]/2.5
    get_width(::NDot) = r[]/2.5
    get_width(::OPlus) = r[]*1.4
    boxsize(b::Gadget) = (w = get_width(b); (w, w))
    function boxsize(b::Box)
        return b.width, b.height
    end
    function boxsize(::MeasureBox)
        return 2 * r[], 2 * r[]
    end

    function render(b::Box, loc)
        setcolor(gate_bgcolor[])
        Luxor.box(Point(loc)*unit[], b.width*unit[], b.height*unit[], :fill)
        setcolor(linecolor[])
        setline(lw[])
        Luxor.box(Point(loc)*unit[], b.width*unit[], b.height*unit[], :stroke)
    end

    function render(d::Dot, loc)
        setcolor(linecolor[])
        circle(Point(loc)*unit[], get_width(d)*unit[]/2, :fill)
    end
    function render(d::Phase, loc)
        x0 = Point(loc)*unit[]
        setcolor(linecolor[])
        circle(x0, get_width(d)*unit[]/2, :fill)
        setcolor(textcolor[])
        fontsize(textsize[])
        fontface(fontfamily[])
        text(d.text, x0+Point(8,8); valign=:middle, halign=:center)
    end
    function render(d::NDot, loc)
        setcolor(gate_bgcolor[])
        circle(Point(loc)*unit[], get_width(d)*unit[]/2, :fill)
        setcolor(linecolor[])
        setline(lw[])
        circle(Point(loc)*unit[], get_width(d)*unit[]/2, :stroke)
    end
    function render(::Cross, loc)
        setline(lw[])
        setcolor(linecolor[])
        line(Point(loc[1]-r[]/sqrt(2), loc[2]-r[]/sqrt(2))*unit[], Point(loc[1]+r[]/sqrt(2), loc[2]+r[]/sqrt(2))*unit[], :stroke)
        line(Point(loc[1]-r[]/sqrt(2), loc[2]+r[]/sqrt(2))*unit[], Point(loc[1]+r[]/sqrt(2), loc[2]-r[]/sqrt(2))*unit[], :stroke)
    end
    function render(d::OPlus, loc)
        w = get_width(d) / 2
        setcolor(gate_bgcolor[])
        circle(Point(loc)*unit[], w*unit[], :fill)
        setcolor(linecolor[])
        setline(lw[])
        x0 = Point(loc)*unit[]
        circle(x0, w*unit[], :stroke)
        line(x0+Point(-w*unit[], 0.0), x0+Point(w*unit[], 0.0*unit[]), :stroke)
        line(x0+Point(0.0, -w*unit[]), x0+Point(0.0*unit[], w*unit[]), :stroke)
    end
    function render(::MeasureBox, loc)
        x0 = Point(loc)*unit[]
        setcolor(gate_bgcolor[])
        box(x0, 2*r[]*unit[], 2*r[]*unit[], :fill)
        setcolor(linecolor[])
        setline(lw[])
        box(x0, 2*r[]*unit[], 2*r[]*unit[], :stroke)
        move(x0+Point(-0.8*r[], 0.5*r[])*unit[])
        curve(
            x0+Point(-0.8*r[], -0.6*r[])*unit[],
            x0+Point(0.8*r[], -0.6*r[])*unit[],
            x0+Point(0.8*r[], 0.5*r[])*unit[])
        strokepath()
        line(x0+Point(0.0, 0.5*r[])*unit[], x0+Point(0.7*r[], -0.4*r[])*unit[], :stroke)
    end

    function render(::Line, locs)
        setcolor(linecolor[])
        setline(lw[])
        line(Point(locs[1])*unit[], Point(locs[2])*unit[], :stroke)
    end
    function render(t::Text, loctxt)
        loc, txt, width, height = loctxt
        fontsize(t.fontsize)
        fontface(fontfamily[])
        #fontface("Dejavu Sans")
        setcolor(textcolor[])
        if contains(txt, '\n')
            for (i, txt) in enumerate(split(loctxt[2], "\n"))
                text(txt, Point(loc)*unit[]+i*Point(0, t.fontsize)-Point((width-0.1)*unit[]/2, height*unit[]/2); halign=:left, valign=:middle)
            end
        else
            text(txt, Point(loc)*unit[]; halign=:center, valign=:middle)
        end
    end

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
    frontier::Vector{Int}
    w_depth::Float64
    w_line::Float64
    gatestyles::CircuitStyles.GateStyles
end

nline(c::CircuitGrid) = length(c.frontier)
depth(c::CircuitGrid) = frontier(c, 1, nline(c))
Base.getindex(c::CircuitGrid, i, j) = (c.w_depth*i, c.w_line*j)
Base.typed_vcat(c::CircuitGrid, ij1, ij2) = (c[ij1...], c[ij2...])

function CircuitGrid(nline::Int; w_depth=1.0, w_line=1.0, gatestyles=CircuitStyles.GateStyles())
    CircuitGrid(zeros(Int, nline), w_depth, w_line, gatestyles)
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
    loc_brush_texts = map(loc_brush_texts) do (j, b, txt)
        if length(j) != 0
            wspace, _ = text_width_and_size(txt)
            hspace = (maximum(j)-minimum(j)) * c.w_line
            # make box larger
            b = b isa CircuitStyles.Box ? CircuitStyles.Box(b.height + hspace, b.width + wspace) : b
            boxwidth, boxheight = CircuitStyles.boxsize(b)
            push!(boxwidths, boxwidth)
            push!(boxheights, boxheight)
        end
        (j, b, txt)
    end
    max_width = maximum(boxwidths)
    ncolumn = max(1, ceil(Int, max_width/c.w_depth + 0.2))  # 0.1 is the minimum gap between two columns

    ipre = frontier(c, minimum(locs):maximum(locs)...)
    i = ipre + ncolumn/2
    local jpre
    for (k, ((j, b, txt), boxheight)) in enumerate(zip(loc_brush_texts, boxheights))
        length(j) == 0 && continue
        _, fontsize = text_width_and_size(txt)
        jmid = (minimum(j)+maximum(j))/2
        CircuitStyles.render(b, c[i, jmid])
        CircuitStyles.render(CircuitStyles.Text(fontsize), (c[i,jmid], txt, CircuitStyles.boxsize(b)...))
        # use line to connect blocks in the same gate
        if k!=1
            CircuitStyles.render(c.gatestyles.line, c[(i, jmid-boxheight/2/c.w_line); (i, jpre)])
        end
        jpre = jmid + boxheight/2/c.w_line
    end

    #jmin, jmax = min(locs..., nline(c)), max(locs..., 1)
    # connect horizontal lines
    for (width, (j, b, txt)) in zip(boxwidths, loc_brush_texts)
        for jj in j
            CircuitStyles.render(c.gatestyles.line, c[(c.frontier[jj], jj); (i-width/2/c.w_depth, jj)])
            CircuitStyles.render(c.gatestyles.line, c[(i+width/2/c.w_depth, jj); (ipre+ncolumn, jj)])
            c.frontier[jj] = ipre + ncolumn
        end
    end
    for j in setdiff(minimum(locs):maximum(locs), locs)
        CircuitStyles.render(c.gatestyles.line, c[(c.frontier[j], j); (ipre+ncolumn, j)])
        c.frontier[j] = ipre + ncolumn
    end
end

function text_width_and_size(text)
    lines = split(text, "\n")
    widths = map(x->textwidth(x), lines)
    (mw, loc) = findmax(widths)
    fontsize = mw > 3 ? CircuitStyles.paramtextsize[] : CircuitStyles.textsize[]
    # -2 because the gate has a default size
    #width = max(W - 4, 0) * fontsize * 0.016  # mm to cm
    Luxor.fontsize(fontsize)
    Luxor.fontface(CircuitStyles.fontfamily[])
    width, height = Luxor.textextents(lines[loc])[3:4]
    w = max(width / CircuitStyles.unit[] - CircuitStyles.r[]*2 + 0.2, 0.0)
    return w, fontsize
end

function initialize!(c::CircuitGrid; starting_texts, starting_offset)
    starting_texts !== nothing && for j=1:nline(c)
        CircuitStyles.render(c.gatestyles.text, (c[starting_offset, j], string(starting_texts[j]), c.w_depth, c.w_line))
    end
end

function finalize!(c::CircuitGrid; show_ending_bar, ending_offset, ending_texts)
    i = frontier(c, 1, nline(c))
    for j=1:nline(c)
        show_ending_bar && CircuitStyles.render(c.gatestyles.line, c[(i, j-0.2); (i, j+0.2)])
        CircuitStyles.render(c.gatestyles.line, c[(i, j); (c.frontier[j], j)])
        ending_texts !== nothing && CircuitStyles.render(c.gatestyles.text, (c[i+ending_offset, j], string(ending_texts[j]), c.w_depth, c.w_line))
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
function draw!(c::CircuitGrid, p::AbstractChannel, address, controls)
    bts = (c.gatestyles.g, "*")
    _draw!(c, [controls..., (getindex.(Ref(address), occupied_locs(p)), bts[1], bts[2])])
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
    CircuitStyles.barrier_for_chain[] && set_barrier!(c, Int[address..., controls...])
    for block in subblocks(p)
        draw!(c, block, address, controls)
    end
    CircuitStyles.barrier_for_chain[] && set_barrier!(c, Int[address..., controls...])
end

function set_barrier!(c::CircuitGrid, locs::AbstractVector{Int})
    front = maximum(c.frontier[locs])
    for loc in locs
        if c.frontier[loc] < front
            CircuitStyles.render(c.gatestyles.line, c[(c.frontier[loc], loc); (front, loc)])
            c.frontier[loc] = front
        end
    end
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
            # read i-th bit value
            val = Int(m.postprocess.x)>>(i-1) & 1
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

for B in [:GeneralMatrixBlock, :Add]
    @eval function draw!(c::CircuitGrid, cb::$B, address, controls)
        length(address) == 0 && return
        _draw!(c, [controls..., (address, c.gatestyles.g, string(cb))])
    end
end

function draw!(c::CircuitGrid, cb::LabelBlock, address, controls)
    length(address) == 0 && return
    CircuitStyles.gate_bgcolor[], temp = cb.color, CircuitStyles.gate_bgcolor[]
    _draw!(c, [controls..., (address, c.gatestyles.g, string(cb))])
    CircuitStyles.gate_bgcolor[] = temp
end

function draw!(c::CircuitGrid, cb::LineAnnotation, address, controls)
    @assert length(address) == 1 && isempty(controls) "LineAnnotation should be a single line, without control."
    CircuitStyles.textcolor[], temp = cb.color, CircuitStyles.textcolor[]
    _annotate!(c, address[1], cb.name)
    CircuitStyles.textcolor[] = temp
end
function _annotate!(c::CircuitGrid, loc::Integer, name::AbstractString)
    wspace, fontsize = text_width_and_size(name)
    i = frontier(c, loc) + 0.1
    CircuitStyles.render(CircuitStyles.Text(fontsize), (c[i, loc-0.2], name, wspace, fontsize))
end

# [:KronBlock, :RepeatedBlock, :CachedBlock, :Subroutine, :(YaoBlocks.AD.NoParams)]
function draw!(c::CircuitGrid, p::CompositeBlock, address, controls)
    barrier_style = CircuitStyles.barrier_for_chain[]
    CircuitStyles.barrier_for_chain[] = false
    draw!(c, YaoBlocks.Optimise.to_basictypes(p), address, controls)
    CircuitStyles.barrier_for_chain[] = barrier_style
end
for (GATE, SYM) in [(:XGate, :Rx), (:YGate, :Ry), (:ZGate, :Rz)]
    @eval get_brush_texts(c, b::RotationGate{D,T,<:$GATE}) where {D,T} = (c.gatestyles.g, "$($(SYM))($(pretty_angle(b.theta)))")
end

pretty_angle(theta) = string(theta)
function pretty_angle(theta::AbstractFloat)
    c = continued_fraction(theta/π, 10)
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
"""
    continued_fraction(ϕ, n::Int) -> Rational

Obtain `s` and `r` from `ϕ` that satisfies `|s//r - ϕ| ≦ 1/2r²`
"""
function continued_fraction(fl, n::Int)
    if n == 1 || abs(mod(fl, 1)) < 1e-10
        Rational(floor(Int, fl), 1)
    else
        floor(Int, fl) + 1//continued_fraction(1/mod(fl, 1), n-1)
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
get_brush_texts(c, b::ShiftGate) = (c.gatestyles.g, "φ($(pretty_angle(b.theta)))")
get_brush_texts(c, b::PhaseGate) = (CircuitStyles.Phase("$(pretty_angle(b.theta))"), "")
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
"""
    vizcircuit(circuit; w_depth=0.85, w_line=0.75, format=:svg, filename=nothing,
        show_ending_bar=false, starting_texts=nothing, starting_offset=-0.3,
        ending_texts=nothing, ending_offset=0.3)

Visualize a `Yao` quantum circuit.

### Keyword Arguments
* `w_depth` is the circuit column width.
* `w_line` is the circuit row width.
* `format` can be `:svg`, `:png` or `:pdf`.
* `filename` can be `"*.svg"`, `"*.png"`, `"*.pdf"` or nothing (not saving to a file).
* `starting_texts` and `ending_texts` are texts shown before and after the circuit.
* `starting_offset` and `end_offset` are offsets (real values) for starting and ending texts.
* `show_ending_bar` is a boolean switch to show ending bar.

### Styles
To change the gates styles like colors and lines, please modify the constants in submodule `CircuitStyles`.
They are defined as:

* CircuitStyles.unit = Ref(60)                      # number of points in a unit
* CircuitStyles.r = Ref(0.2)                        # size of nodes
* CircuitStyles.lw = Ref(1.0)                       # line width
* CircuitStyles.textsize = Ref(16.0)                # text size
* CircuitStyles.paramtextsize = Ref(10.0)           # text size (longer texts)
* CircuitStyles.fontfamily = Ref("JuliaMono")       # font family
* CircuitStyles.linecolor = Ref("#000000")          # line color
* CircuitStyles.gate_bgcolor = Ref("transparent")   # gate background color
* CircuitStyles.textcolor = Ref("#000000")          # text color
"""
function vizcircuit(blk::AbstractBlock; w_depth=0.85, w_line=0.75, format=:svg, filename=nothing,
        show_ending_bar=false, starting_texts=nothing, starting_offset=-0.3,
        ending_texts=nothing, ending_offset=0.3, gatestyles=CircuitStyles.GateStyles())
    img = circuit_canvas(nqudits(blk); w_depth, w_line, show_ending_bar, starting_texts, starting_offset,
            ending_texts, ending_offset, gatestyles, format, filename) do c
        addblock!(c, blk)
    end
    return img
end

addblock!(c::CircuitGrid, blk::AbstractBlock) = draw!(c, blk, collect(1:nqudits(blk)), [])
addblock!(c::CircuitGrid, blk::Function) = addblock!(c, blk(nline(c)))

function circuit_canvas(f, nline::Int; format=:svg, filename=nothing, w_depth=0.85, w_line=0.75,
        show_ending_bar=false, starting_texts=nothing, starting_offset=-0.3, ending_texts=nothing,
        ending_offset=0.3, gatestyles=CircuitStyles.GateStyles())
    # the first time to estimate the canvas size
    Luxor.Drawing(50, 50, :png)
    c = CircuitGrid(nline; w_depth, w_line, gatestyles)
    initialize!(c; starting_texts, starting_offset)
    f(c)
    finalize!(c; show_ending_bar, ending_texts, ending_offset)
    Luxor.finish()
    # the second time draw
    u = CircuitStyles.unit[]
    a, b = ceil(Int, (depth(c)+1)*w_depth*u), ceil(Int, nline*w_line*u)
    _luxor(a, b, w_depth/2*u, -w_line/2*u; format, filename) do
        c = CircuitGrid(nline; w_depth, w_line, gatestyles)
        initialize!(c; starting_texts, starting_offset)
        f(c)
        finalize!(c; show_ending_bar, ending_texts, ending_offset)
    end
end

function _luxor(f, Dx, Dy, offsetx, offsety; format, filename)
    if filename === nothing
        if format == :pdf
            _format = tempname()*".pdf"
        else
            _format = format
        end
    else
        _format = filename
    end
    Luxor.Drawing(round(Int,Dx), round(Int,Dy), _format)
    Luxor.origin(offsetx, offsety)
    f()
    Luxor.finish()
    Luxor.preview()
end

vizcircuit(; kwargs...) = c->vizcircuit(c; kwargs...)

"""
    darktheme!()

Change the default theme to dark.
"""
function darktheme!()
    CircuitStyles.linecolor[] = "#FFFFFF"
    CircuitStyles.textcolor[] = "#FFFFFF"
    BlochStyles.color[] = "#FFFFFF"
    BlochStyles.axes_colors .= ["#FFFFFF", "#FFFFFF", "#FFFFFF"]
end

"""
    lighttheme!()

Change the default theme to light.
"""
function lighttheme!()
    CircuitStyles.linecolor[] = "#000000"
    CircuitStyles.textcolor[] = "#000000"
    BlochStyles.color[] = "#000000"
    BlochStyles.axes_colors .= ["#000000", "#000000", "#000000"]
end
