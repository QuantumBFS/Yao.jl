using MLStyle

"""
    @yao_str
    yao"..."

The mark up language for quantum circuit.
"""
macro yao_str(str::String)
    yaofromstring(str)
end

function yaofromstring(x::String)
    ex = Meta.parse(x)
    @match ex begin
        Expr(:let, header, body) => begin
            info = ParseInfo(-1, "")
            if header.head != :block
                header = [header]
            else
                header = header.args
            end
            for hd in header
                @match hd begin
                    :(nqubits = $n) => (info.nbit = Int(n))
                    :(version = $v) => (info.version = String(v))
                    _ => error("unknown configuration $header")
                end
            end
            parse_ex(body |> rmlines, info)
        end
        _ => error("wrong format, expect expression like `let nqubits=5 GATEDEF end`, got $ex")
    end
end

yaofromfile(x::String) = yaofromstring(read(x, String))
parse_ex(ex, nbit::Int) = parse_ex(ex, ParseInfo(nbit, ""))

mutable struct ParseInfo
    nbit::Int
    version::String
end

function parse_ex(ex, info::ParseInfo)
    @match ex begin
        :(version = $vnumber) => (info.version = String(vnumber); nothing)
        :(nqubits = $x) => (info.nbit = Int(x); nothing)
        ::Nothing => nothing
        :($g') => :($(parse_ex(g, info))')
        :($a * $b) => :($(Number(a)) * $(parse_ex(b, info)))
        :(kron($(args...))) => :(kron($(parse_ex.(args, Ref(ParseInfo(1, info.version)))...)))
        :(repeat($(exloc...)) => $g) => begin
            loc = render_loc((exloc...,), info.nbit)
            :(repeat($(info.nbit), $(parse_ex(g, ParseInfo(1, info.version))), $loc))
        end
        :(cache($g)) => :(cache($(parse_ex(g, info))))
        :(rot($g, $theta)) => :(rot($(parse_ex(g, info)), $(Number(theta))))
        :(time($dt) => $h) => :(time_evolve($(parse_ex(h, info)), $(Number(dt))))
        :($exloc => Measure) => parse_ex(:($exloc => Measure(nothing) => nothing), info)
        :($exloc => Measure($op)) => parse_ex(:($exloc => Measure($op) => nothing), info)
        :($exloc => Measure => $post) => parse_ex(:($exloc => Measure(nothing) => $post), info)
        :($exloc => Measure($op) => $post) => begin
            locs = exloc == :ALL ? :(AllLocs()) : render_loc(exloc, info.nbit)
            op = op isa Nothing || op == :nothing ? :(ComputationalBasis()) :
                    parse_ex(op, exloc == :ALL ? info : ParseInfo(length(locs), info.version))
            @match post begin
                ::Nothing || :nothing => :(Measure($(info.nbit); locs = $locs, operator = $(op)))
                :(resetto($(rbits...))) => begin
                    cb = bit_literal(render_bitstring.(rbits)...)
                    :(Measure($(info.nbit); locs = $locs, operator = $(op), resetto = $cb))
                end
                :remove => :(Measure($(info.nbit); locs = $locs, operator = $(op), remove = true))
            end
        end
        :(+($(args...))) => :(+($(parse_ex.(args, Ref(info))...)))
        :(focus($(exloc...)) => $g) => begin
            loc = render_loc((exloc...,), info.nbit)
            :(concentrate($(info.nbit), $(parse_ex(g, ParseInfo(length(loc), info.version))), $loc))
        end
        :(begin
            $(cargs...)
        end) => begin
            args = filter(x -> x !== nothing, [parse_ex(arg, info) for arg in cargs])
            :(chain($(info.nbit), [$(args...)]))
        end
        :($exloc => $gate) => begin
            loc = render_loc(exloc, info.nbit)
            :(put($(info.nbit), $loc => $(parse_ex(gate, ParseInfo(length(loc), info.version)))))
        end
        :($(cargs...), $exloc => $gate) => begin
            loc = render_loc(exloc, info.nbit)
            cbits = render_cloc.(cargs, Ref(info))
            if cbits[1] isa Integer
                :(control(
                    $(info.nbit),
                    $cbits,
                    $loc => $(parse_ex(gate, ParseInfo(length(loc), info.version))),
                ))
            else
                :(kron($(info.nbit), $(cbits...), $loc => $(parse_ex(gate, ParseInfo(1, info.version)))))
            end
        end
        :($f($(args...))) => gate_expr(Val(Symbol(f)), args, info)

        ::LineNumberNode => nothing
        ::Symbol => ex  # const gate
        _ => error("scipt format error! got $ex of type $(typeof(ex))")
    end
end

function check_dumpload(gate::AbstractBlock{N}) where {N}
    gate2 = eval(parse_ex(dump_gate(gate), N))
    gate2 == gate || mat(gate2) ≈ mat(gate)
end

render_bitstring(ex) = @match ex begin
    ::Number => begin
        if ex == 1 || ex == 0
            ex
        else
            error("expect a bitstring like `1` or `(1,0)`, got $ex")
        end
    end
    ::Tuple => render_bitstring.(ex)
    :($(args...),) => (render_bitstring.(args)...,)
    _ => error("expect a bitstring like `1` or `(1,0)`, got $ex")
end

render_loc(ex, nbit::Int) = @match ex begin
    :($(args...),) => (render_loc.(args, nbit)...,)
    ::Number => Int(ex)
    :($a:$b) => Int(a):Int(b)
    :ALL => (1:nbit...,)
    :($a:$step:$b) => Int(a):Int(step):Int(b)
    ::Tuple => Int.(ex)
    ::UnitRange{Int} => ex
    _ => error("expect a location specification like `2`, `2:5` or `(2,3)`, got $ex")
end

render_cloc(ex, info) = @match ex begin
    :($a => C($b)) => begin
        if !(b == 1 || b == 0)
            error("expect a control values `0` or `1`, got $ex")
        end
        Int(a) * (2 * Int(b) - 1)
    end
    :($a => C) => render_cloc(:($a => C(1)), info)
    :($a => $g) => :($(render_loc(a, info.nbit)) => $(parse_ex(g, ParseInfo(1, info.version))))
    _ => error("expect a control location specification like `2=>0` or `3=>1`, got $ex")
end

"""
    gate_expr(::Val{G}, args, info)

Obtain the gate constructior from its YaoScript expression.
`G` is a symbol for the gate type,
the default constructor is `G(args...)`.
`info` contains the informations about the number of qubit and Yao version.
"""
function gate_expr(::Val{G}, args, info) where {G}
    throw(NotImplementedError(:gate_expr, (Val(G), args, info)))
end

render_arg(ex, info) = @match ex begin
    # locs
    :($(args...),) => (render_loc.(args, info.nbit)...,)
    ::Integer => Int(ex)
    :($a:$b) => Int(a):Int(b)
    :ALL => (1:nbit...,)
    :($a:$step:$b) => Int(a):Int(step):Int(b)
    ::Tuple => Int.(ex)

    # floating point numbers
    ::Number => Number(ex)

    # Pair of (loc => gate)
    :($a => $g) => begin
        locs = render_loc(a, info.nbit)
        :($(locs) => $(parse_ex(g, ParseInfo(length(locs), info.version))))
    end

    # try parse a gate
    _ => parse_ex(ex, info)
end
