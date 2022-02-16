using Viznet: canvas
import Viznet
using Compose: CurvePrimitive, Form
using YaoBlocks
using BitBasis

export CircuitStyles, CircuitGrid, circuit_canvas, vizcircuit, pt, cm

module CircuitStyles
    using Compose
    import Viznet
    const r = Ref(0.2)
	const lw = Ref(1pt)
	const textsize = Ref(16pt)
	const paramtextsize = Ref(10pt)
	const fontfamily = Ref("Helvetica Neue")
    const linecolor = Ref("#000000")
    const gate_bgcolor = Ref("#FFFFFF")
    const textcolor = Ref("#000000")
    const scale = Ref(1.0)
    G() = compose(context(), rectangle(-r[], -r[], 2*r[], 2*r[]), fill(gate_bgcolor[]), stroke(linecolor[]), linewidth(lw[]))
    C() = compose(context(), circle(0.0, 0.0, r[]/3), fill(linecolor[]), linewidth(0))
    NC() = compose(context(), circle(0.0, 0.0, r[]/3), fill(gate_bgcolor[]), stroke(linecolor[]), linewidth(lw[]))
    X() = compose(context(), xgon(0.0, 0.0, r[], 4), fill(linecolor[]), linewidth(0))
	NOT() = compose(context(),
                    (context(), circle(0.0, 0.0, r[]), stroke(linecolor[]), linewidth(lw[]), fill("transparent")),
                    (context(), polygon([(-r[], 0.0), (r[], 0.0)]), stroke(linecolor[]), linewidth(lw[])),
                    (context(), polygon([(0.0, -r[]), (0.0, r[])]), stroke(linecolor[]), linewidth(lw[]))
               )
    WG() = compose(context(), rectangle(-1.5*r[], -r[], 3*r[], 2*r[]), fill(gate_bgcolor[]), stroke(linecolor[]), linewidth(lw[]))
    MULTIGATE(h) = compose(context(), rectangle(-1.5*r[], -(h/2+r[]), 3*r[], (h+2*r[])), fill(gate_bgcolor[]), stroke(linecolor[]), linewidth(lw[]))
    LINE() = compose(context(), line(), stroke(linecolor[]), linewidth(lw[]))
    TEXT() = compose(context(), text(0.0, 0.0, "", hcenter, vcenter), fontsize(textsize[]), fill(textcolor[]), font(fontfamily[]))
    PARAMTEXT() = compose(context(), text(0.0, 0.0, "", hcenter, vcenter), fontsize(paramtextsize[]), fill(textcolor[]), font(fontfamily[]))
    MEASURE() = compose(context(),
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

    Base.@kwdef struct GateStyles
        g = G()
        c = C()
        x = X()
        nc = NC()
        not = NOT()
        wg = WG()
        line = LINE()
        text = TEXT()
        paramtext = PARAMTEXT()
        measure = MEASURE()
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
    locs = Iterators.flatten(getindex.(loc_brush_texts, 1)) |> collect
    i = frontier(c, locs...) + 1
	local jpre
	loc_brush_texts = sort(loc_brush_texts, by=x->first(x[1]))
    for (k, (j, b, txt)) in enumerate(loc_brush_texts)
        length(j) == 0 && continue
        jmid = (minimum(j)+maximum(j))/2
		b >> c[i, jmid]
		if length(txt) >= 3
			c.gatestyles.paramtext >> (c[i, jmid], txt)
		elseif length(txt) >= 1
			c.gatestyles.text >> (c[i, jmid], txt)
		end
		if k!=1
			c.gatestyles.line >> c[(i, jmid); (i, jpre)]
		end
		jpre = jmid
    end

	jmin, jmax = min(locs..., nline(c)), max(locs..., 1)
	for j = jmin:jmax
		c.gatestyles.line >> c[(i, j); (c.frontier[j], j)]
		c.frontier[j] = i
	end
end

function _draw_continuous_multiqubit!(c::CircuitGrid, loc_text)
    (start, stop), txt = loc_text
    stop-start<0 && return
    b = CircuitStyles.MULTIGATE((stop-start) * c.w_line)
    i = frontier(c, start:stop...) + 1
    j = (stop+start)/2

    b >> c[i, j]
    if length(txt) >= 3
        c.gatestyles.paramtext >> (c[i, j], txt)
    elseif length(txt) >= 1
        c.gatestyles.text >> (c[i, j], txt)
    end
	for j = start:stop
		c.gatestyles.line >> c[(i, j); (c.frontier[j], j)]
		c.frontier[j] = i
	end
end

function initialize!(c::CircuitGrid; starting_texts, starting_offset)
	starting_texts !== nothing && for j=1:nline(c)
        c.gatestyles.text >> (c[starting_offset, j], string(starting_texts[j]))
	end
end

function finalize!(c::CircuitGrid; show_ending_bar, ending_offset, ending_texts)
    i = frontier(c, 1, nline(c)) + 1
	for j=1:nline(c)
		show_ending_bar && c.gatestyles.line >> c[(i, j-0.2); (i, j+0.2)]
		c.gatestyles.line >> c[(i, j); (c.frontier[j], j)]
        ending_texts !== nothing && c.gatestyles.text >> (c[i+ending_offset, j], string(ending_texts[j]))
	end
	c.frontier .= i
end

# elementary
function draw!(c::CircuitGrid, b::AbstractBlock, address, controls)
    error("block type $(typeof(b)) does not support visualization.")
end

function draw!(c::CircuitGrid, p::PrimitiveBlock{M}, address, controls) where M
	bts = length(controls)>=1 ? get_cbrush_texts(c, p) : get_brush_texts(c, p)
	_draw!(c, [controls..., [(address[i], bts[i]...) for i=occupied_locs(p)]...])
end

function draw!(c::CircuitGrid, p::Scale, address, controls)
	fp = YaoBlocks.factor(p)
	if !(abs(fp) ≈ 1)
		error("can not visualize non-phase factor.")
	end
	draw!(c, YaoBlocks.phase(angle(fp)), [first(address)], controls)
	draw!(c, p.content, address, controls)
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

function draw!(c::CircuitGrid, cb::LabelBlock{GT}, address, controls) where {GT}
    length(address) == 0 && return
    is_continuous_chunk(address) || error("address not continuous in a block marked as continous.")
	_draw!(c, [controls..., (minimum(address):maximum(address), CircuitStyles.MULTIGATE((length(address)-1)*c.w_line), cb.name)])
end

for (GATE, SYM) in [(:XGate, :Rx), (:YGate, :Ry), (:ZGate, :Rz)]
	@eval get_brush_texts(c, b::RotationGate{2,T,<:$GATE}) where T = [(c.gatestyles.wg, "$($(SYM))($(pretty_angle(b.theta)))")]
end

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

get_brush_texts(c, b::ConstGate.CNOTGate) = [(c.gatestyles.c, ""), (c.gatestyles.x, "")]
get_brush_texts(c, b::ConstGate.CZGate) = [(c.gatestyles.c, ""), (c.gatestyles.c, "")]
get_brush_texts(c, b::ConstGate.ToffoliGate) = [(c.gatestyles.c, ""), (c.gatestyles.c, ""), (c.gatestyles.x, "")]
get_brush_texts(c, b::ConstGate.SdagGate) = [(c.gatestyles.g, "S'")]
get_brush_texts(c, b::ConstGate.TdagGate) = [(c.gatestyles.g, "T'")]
get_brush_texts(c, b::ConstGate.PuGate) = [(c.gatestyles.g, "P+")]
get_brush_texts(c, b::ConstGate.PdGate) = [(c.gatestyles.g, "P-")]
get_brush_texts(c, b::ConstGate.P0Gate) = [(c.gatestyles.g, "P₀")]
get_brush_texts(c, b::ConstGate.P1Gate) = [(c.gatestyles.g, "P₁")]
get_brush_texts(c, b::ConstGate.I2Gate) = []
get_brush_texts(c, b::SWAPGate) = [(c.gatestyles.x, ""), (c.gatestyles.x, "")]
get_brush_texts(c, b::PrimitiveBlock{M}) where M = fill((c.gatestyles.g, ""), M)
get_brush_texts(c, b::PrimitiveBlock{1}) = [(c.gatestyles.g, "")]
get_brush_texts(c, b::ShiftGate) = [(c.gatestyles.wg, "ϕ($(pretty_angle(b.theta)))")]
get_brush_texts(c, b::PhaseGate) = [(c.gatestyles.wg, "^$(pretty_angle(b.theta))")]
function get_brush_texts(c, b::T) where T<:ConstantGate{1}
    namestr = string(T.name.name)
    if endswith(namestr, "Gate")
        namestr = namestr[1:end-4]
    end
    [(c.gatestyles.g, namestr)]
end

get_cbrush_texts(c, b::PrimitiveBlock) = get_brush_texts(c, b)
get_cbrush_texts(c, b::XGate) = [(c.gatestyles.not, "")]
get_cbrush_texts(c, b::ZGate) = [(c.gatestyles.c, "")]

# front end
plot(blk::AbstractBlock; kwargs...) = vizcircuit(blk; kwargs...)
function vizcircuit(blk::AbstractBlock; w_depth=0.85, w_line=0.75, scale=1.0, show_ending_bar=false, starting_texts=nothing, starting_offset=-0.3, ending_texts=nothing, ending_offset=0.3, graphsize=1.0, gatestyles=CircuitStyles.GateStyles())
    CircuitStyles.scale[] = scale
    img = circuit_canvas(nqubits(blk); w_depth, w_line, show_ending_bar, starting_texts, starting_offset, ending_texts, ending_offset, graphsize, gatestyles) do c
		basicstyle(blk) >> c
	end
    CircuitStyles.scale[] = 1.0
    return img |> rescale(scale)
end

function circuit_canvas(f, nline::Int; w_depth=0.85, w_line=0.75, show_ending_bar=false, starting_texts=nothing, starting_offset=-0.3, ending_texts=nothing, ending_offset=0.3, graphsize=1.0, gatestyles=CircuitStyles.GateStyles())
	c = CircuitGrid(nline; w_depth, w_line, gatestyles)
	g = canvas() do
        initialize!(c; starting_texts, starting_offset)
        f(c)
        finalize!(c; show_ending_bar, ending_texts, ending_offset)
	end
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

function basicstyle(blk::AbstractBlock)
	YaoBlocks.Optimise.simplify(blk, rules=[YaoBlocks.Optimise.to_basictypes])
end
