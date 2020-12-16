using Viznet: canvas
import Viznet
using Compose: CurvePrimitive, Form
using YaoBlocks
using BitBasis

export CircuitStyles, CircuitGrid, circuit_canvas, vizcircuit

module CircuitStyles
    using Compose
    import Viznet
    const r = Ref(0.2)
	const lw = Ref(1pt)
	const textsize = Ref(16pt)
	const paramtextsize = Ref(10pt)
	const fontfamily = Ref("Helvetica Neue")
    G() = compose(context(), rectangle(-r[], -r[], 2*r[], 2*r[]), fill("white"), stroke("black"), linewidth(lw[]))
    C() = compose(context(), circle(0.0, 0.0, r[]/3), fill("black"))
    NC() = compose(context(), circle(0.0, 0.0, r[]/3), fill("white"), stroke("black"), linewidth(lw[]))
    X() = compose(context(), xgon(0.0, 0.0, r[], 4), fill("black"))
	NOT() = compose(context(),
               (context(), circle(0.0, 0.0, r[]), stroke("black"), linewidth(lw[]), fill("transparent")),
               (context(), polygon([(-r[], 0.0), (r[], 0.0)]), stroke("black"), linewidth(lw[])),
               (context(), polygon([(0.0, -r[]), (0.0, r[])]), stroke("black"), linewidth(lw[]))
               )
    WG() = compose(context(), rectangle(-1.5*r[], -r[], 3*r[], 2*r[]), fill("white"), stroke("black"), linewidth(lw[]))
    LINE() = compose(context(), line(), stroke("black"), linewidth(lw[]))
	TEXT() = compose(context(), text(0.0, 0.0, "", hcenter, vcenter), fontsize(textsize[]), font(fontfamily[]))
    PARAMTEXT() = compose(context(), text(0.0, 0.0, "", hcenter, vcenter), fontsize(paramtextsize[]), font(fontfamily[]))
    MEASURE() = compose(context(),
        rectangle(-r[], -r[], 2*r[], 2*r[]), fill("white"), stroke("black"), linewidth(lw[]),
        compose(context(), curve((-0.8*r[], 0.5*r[]), (-0.8*r[], -0.6*r[]), (0.8*r[], -0.6*r[]), (0.8*r[], 0.5*r[])), stroke("black"), linewidth(lw[])),
        compose(context(), line([(0.0, 0.5*r[]), (0.7*r[], -0.4*r[])]), stroke("black"), linewidth(lw[])),
        begin
            ns = Viznet.nodestyle(:triangle, fill("black"); r=0.1*r[], θ=atan(0.7, 0.9))
            Viznet.inner_most_containers(ns) do c
                Viznet.update_locs!(c.form_children, [(0.7*r[], -0.4*r[])])
            end
            ns
        end
        )
	function setlw(_lw)
		lw[] = _lw
	end
	function setr(_r)
		r[] = _r
	end
	function settextsize(_textsize)
		textsize[] = _textsize
	end
	function setparamtextsize(_paramtextsize)
		paramtextsize[] = _paramtextsize
	end
	function setfontfamily(_fontfamily)
		fontfamily[] = _fontfamily
	end
end

struct CircuitGrid
    frontier::Vector{Int}
	w_depth::Float64
	w_line::Float64
end

nline(c::CircuitGrid) = length(c.frontier)
depth(c::CircuitGrid) = frontier(c, 1, nline(c))
Base.getindex(c::CircuitGrid, i, j) = (c.w_depth*i, c.w_line*j)
Base.typed_vcat(c::CircuitGrid, ij1, ij2) = (c[ij1...], c[ij2...])

function CircuitGrid(nline::Int; w_depth=1.0, w_line=1.0)
    CircuitGrid(zeros(Int, nline), w_depth, w_line)
end

function frontier(c::CircuitGrid, args...)
    maximum(i->c.frontier[i], min(args..., nline(c)):max(args..., 1))
end

function _draw!(c::CircuitGrid, loc_brush_texts)
    isempty(loc_brush_texts) && return
	locs = getindex.(loc_brush_texts, 1)
    i = frontier(c, locs...) + 1
	local jpre
	loc_brush_texts = sort(loc_brush_texts, by=x->x[1])
    for (k, (j, b, txt)) in enumerate(loc_brush_texts)
		b >> c[i, j]
		if length(txt) >= 3
			CircuitStyles.PARAMTEXT() >> (c[i, j], txt)
		elseif length(txt) >= 1
			CircuitStyles.TEXT() >> (c[i, j], txt)
		end
		if k!=1
			CircuitStyles.LINE() >> c[(i, j); (i, jpre)]
		end
		jpre = j
    end

	jmin, jmax = min(locs..., nline(c)), max(locs..., 1)
	for j = jmin:jmax
		CircuitStyles.LINE() >> c[(i, j); (c.frontier[j], j)]
		c.frontier[j] = i
	end
end

function finalize!(c::CircuitGrid)
    i = frontier(c, 1, nline(c)) + 1
	for j=1:nline(c)
		CircuitStyles.LINE() >> c[(i, j-0.2); (i, j+0.2)]
		CircuitStyles.LINE() >> c[(i, j); (c.frontier[j], j)]
	end
	c.frontier .= i
end

# elementary
function draw!(c::CircuitGrid, b::AbstractBlock, address, controls)
    error("block type $(typeof(b)) does not support visualization.")
end

function draw!(c::CircuitGrid, p::PrimitiveBlock{M}, address, controls) where M
	bts = length(controls)>=1 ? get_cbrush_texts(p) : get_brush_texts(p)
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
function draw!(c::CircuitGrid, p::ChainBlock{N}, address, controls) where N
	draw!.(Ref(c), subblocks(p), Ref(address), Ref(controls))
end

function draw!(c::CircuitGrid, p::PutBlock{N,M}, address, controls) where {N,M}
	locs = [address[i] for i in p.locs]
	draw!(c, p.content, locs, controls)
end

function draw!(c::CircuitGrid, m::YaoBlocks.Measure{N}, address, controls) where {N,M}
    if m.postprocess isa RemoveMeasured
        error("can not visualize post-processing: `RemoveMeasured`.")
    end
    if !(m.operator isa ComputationalBasis)
        error("can not visualize measure blocks for operators")
    end
    locs = m.locations isa AllLocs ? collect(1:N) : [address[i] for i in m.locations]
    for (i, loc) in enumerate(locs)
        _draw!(c, [(loc, CircuitStyles.MEASURE(), "")])
        if m.postprocess isa ResetTo
            val = readbit(m.postprocess.x, i)
            _draw!(c, [(loc, CircuitStyles.G(), val == 1 ? "P₁" : "P₀")])
        end
    end
end

function draw!(c::CircuitGrid, cb::ControlBlock{N,GT,C}, address, controls) where {N,GT,C}
    ctrl_locs = [address[i] for i in cb.ctrl_locs]
    locs = [address[i] for i in cb.locs]
	mycontrols = [(loc, (bit == 1 ? CircuitStyles.C() : CircuitStyles.NC()), "") for (loc, bit)=zip(ctrl_locs, cb.ctrl_config)]
	draw!(c, cb.content, locs, [controls..., mycontrols...])
end

for (GATE, SYM) in [(:XGate, :Rx), (:YGate, :Ry), (:ZGate, :Rz)]
	@eval get_brush_texts(b::RotationGate{1,T,<:$GATE}) where T = [(CircuitStyles.WG(), "$($(SYM))($(pretty_angle(b.theta)))")]
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

get_brush_texts(b::ConstGate.CNOTGate) = [(CircuitStyles.C(), ""), (CircuitStyles.X(), "")]
get_brush_texts(b::ConstGate.CZGate) = [(CircuitStyles.C(), ""), (CircuitStyles.C(), "")]
get_brush_texts(b::ConstGate.ToffoliGate) = [(CircuitStyles.C(), ""), (CircuitStyles.C(), ""), (CircuitStyles.X(), "")]
get_brush_texts(b::ConstGate.SdagGate) = [(CircuitStyles.G(), "S†")]
get_brush_texts(b::ConstGate.TdagGate) = [(CircuitStyles.G(), "T†")]
get_brush_texts(b::ConstGate.PuGate) = [(CircuitStyles.G(), "P+")]
get_brush_texts(b::ConstGate.PdGate) = [(CircuitStyles.G(), "P-")]
get_brush_texts(b::ConstGate.P0Gate) = [(CircuitStyles.G(), "P₀")]
get_brush_texts(b::ConstGate.P1Gate) = [(CircuitStyles.G(), "P₁")]
get_brush_texts(b::ConstGate.I2Gate) = []
get_brush_texts(b::SWAPGate) = [(CircuitStyles.X(), ""), (CircuitStyles.X(), "")]
get_brush_texts(b::PrimitiveBlock{M}) where M = fill((CircuitStyles.G(), ""), M)
get_brush_texts(b::PrimitiveBlock{1}) = [(CircuitStyles.G(), "")]
get_brush_texts(b::ShiftGate) = [(CircuitStyles.WG(), "ϕ($(pretty_angle(b.theta)))")]
get_brush_texts(b::PhaseGate) = [(CircuitStyles.WG(), "^$(pretty_angle(b.theta))")]
function get_brush_texts(b::T) where T<:ConstantGate{1}
    namestr = string(T.name.name)
    if endswith(namestr, "Gate")
        namestr = namestr[1:end-4]
    end
    [(CircuitStyles.G(), namestr)]
end

get_cbrush_texts(b::PrimitiveBlock) = get_brush_texts(b)
get_cbrush_texts(b::XGate) = [(CircuitStyles.NOT(), "")]
get_cbrush_texts(b::ZGate) = [(CircuitStyles.C(), "")]

# front end
plot(blk::AbstractBlock; kwargs...) = vizcircuit(blk; kwargs...)
function vizcircuit(blk::AbstractBlock; w_depth=0.85, w_line=0.75, scale=1.0)
	circuit_canvas(nqubits(blk); w_depth=w_depth, w_line=w_line) do c
		basicstyle(blk) >> c
	end |> rescale(scale)
end

function circuit_canvas(f, nline::Int; w_depth=0.85, w_line=0.75)
	c = CircuitGrid(nline; w_depth=w_depth, w_line=w_line)
	g = canvas() do
	   f(c)
       finalize!(c)
	end
	a, b = (depth(c)+1)*w_depth, nline*w_line
	Compose.set_default_graphic_size(a*2.5*cm, b*2.5*cm)
	compose(context(0.5/a, -0.5/b, 1/a, 1/b), g)
end

Base.:>>(blk::AbstractBlock{N}, c::CircuitGrid) where N = draw!(c, blk, collect(1:N), [])
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
