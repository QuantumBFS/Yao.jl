export @compose, @line

macro compose(args...)
    if isa(first(args), Integer)
        parse_static_circuit(args...)
    else
        parse_dynamic_circuit(args...)
    end
end

macro line(ex)
end

function parse_const_gate_type(ex::Symbol)
    Symbol(join([ex, "Gate"]))
end

function parse_const_gate_type(ex::Expr)
    first(ex.args) == Symbol(PKGNAME) || throw(ParseError("Invalid Package Name: $(first(ex.args))"))
    Expr(:., Symbol(PKGNAME), QuoteNode(parse_const_gate_type(ex.args[2])))
end

function get_const_gate_type(ex)
    sym = parse_const_gate_type(ex)
    if !isdefined(sym)
        throw(ParseError("Invalid Constant Gate: $sym"))
    end
    sym
end

function parse_static_circuit(n::Int, ex::Symbol)
    quote
        $(esc(ex))
    end
end

function parse_dynamic_circuit(ex::Symbol)
    quote
        QuCircuit.DynamicSized($(esc(ex)))
    end
end

function parse_static_circuit(n::Int, ex)
    if Meta.isexpr(ex, :.) # const block with module name
        gate_type = get_const_gate_type(ex)
        quote
            QuCircuit.kron($n, $(esc(ex)))
        end
    end
end

function parse_dynamic_circuit(ex)
    println("parse dynamic")
end
