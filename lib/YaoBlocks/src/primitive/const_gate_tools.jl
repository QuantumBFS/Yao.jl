export @const_gate

"""
    @const_gate <gate name> = <expr>
    @const_gate <gate name>::<type> = <expr>
    @const_gate <gate>::<type>

This macro simplify the definition of a constant gate. It will automatically bind the matrix form
to a constant which will reduce memory allocation in the runtime.

### Examples

```julia
@const_gate X = ComplexF64[0 1;1 0]
```

or

```julia
@const_gate X::ComplexF64 = [0 1;1 0]
```

You can bind new element types by simply re-declare with a type annotation.

```julia
@const_gate X::ComplexF32
```
"""
macro const_gate(ex, ex2=:(nlevel=2))
    @match ex2 begin
        :(nlevel = $nlevel) => begin
            if !(nlevel isa Integer)
                error("You should provide an integer as the value of `nlevel`! e.g. `nlevel=3`")
            end
            _const_gate(__module__, __source__, ex, nlevel)
        end
        _ => begin
            error("The second argument should be e.g. `nlevel=3`")
        end
    end
end

function _const_gate(__module__::Module, __source__::LineNumberNode, ex, nlevel)
    @match ex begin
        :($name::$t = $expr) => define_gate(__module__, __source__, name, t, expr, nlevel)
        :($name = $expr) => define_gate(__module__, __source__, name, expr, nlevel)
        :($name::$t) => define_typed_binding(__module__, __source__, name, t)
        _ => throw(Meta.ParseError("use @const_gate <gate name> = <expr> or
            @const_gate <gate name>::<type> = <expr> to define new gate, or
            use @const_gate <gate name>::<new type> to bind new type"))
    end
end

"""
    gatetype_name(name)

Returns the name of a constant gate by adding postfix `Gate`.
"""
gatetype_name(name) = Symbol(name, "Gate")

"""
    constant_name(name)

Return the name of a constant binding of the matrix for a constant gate.
"""
constant_name(name) = gensym(Symbol("Const", "_", name))

"""
    define_gate(__module__::Module, __source__::LineNumberNode, name, type, expr)

Return the expression to define a constant gate with given type (value of `expr`
will be converted to given `type`).
"""
function define_gate(__module__::Module, __source__::LineNumberNode, name, type, expr, nlevel)
    const_binding = constant_name(name)
    gt_name = gatetype_name(name)

    return quote
        $(define_binding(__module__, const_binding, type, expr))
        $(define_struct(__module__, __source__, const_binding, name, nlevel))
        $(define_methods(__module__, const_binding, name))
        $(define_properties(__module__, const_binding, name))
    end
end

"""
    define_gate(__module__::Module, __source__::LineNumberNode, name, expr, nlevel)

Return the expression to define a constant gate, use the inferred type.
"""
function define_gate(__module__::Module, __source__::LineNumberNode, name, expr, nlevel)
    const_binding = constant_name(name)
    gt_name = gatetype_name(name)

    return quote
        $(define_binding(__module__, const_binding, expr))
        $(define_struct(__module__, __source__, const_binding, name, nlevel))
        $(define_methods(__module__, const_binding, name))
        $(define_properties(__module__, const_binding, name))
    end
end

"""
    define_typed_binding(__module__::Module, __source__::LineNumberNode, name, type)

Define a new binding to a new type.
"""
function define_typed_binding(__module__::Module, __source__::LineNumberNode, name, type)
    gt_name = gatetype_name(name)
    const_binding = constant_name(name)
    return quote
        @eval $__module__ begin
            if !isdefined($__module__, $(QuoteNode(name)))
                throw(UndefVarError($(QuoteNode(name))))
            end

            const $const_binding = YaoBlocks.mat($type, $gt_name)
            YaoBlocks.mat(::Type{$type}, ::Type{$gt_name}) = $const_binding
        end
    end
end

function define_struct(__module__::Module, __source__::LineNumberNode, const_binding, name, nlevel)
    gt_name = gatetype_name(name)
    ex = Expr(:block)

    # export bindings if this is not in Main
    if __module__ !== Main
        push!(ex.args, :(export $name, $gt_name))
    end
    # calculate new shape
    N = gensym(:N)
    push!(ex.args, :(@eval $__module__ $N = $logdi(size($(const_binding), 1), $nlevel)))

    # we allow overwrite in order to support the following syntax
    # @const_gate X = BLABLA
    # @const_gate X = Correct_Matrix
    if isdefined(__module__, gt_name)
        msg = "$(string(gt_name)) is already defined, overwritten by new definition at $__source__"
        push!(ex.args, :(@warn $msg))
        push!(
            ex.args,
            :(@eval $__module__ @assert $N == $logdi(size(mat($name), 1), $nlevel) "new constant does not have the same size with previous definitions"),
        )
    else
        push!(
            ex.args,
            :(@eval $__module__ Base.@__doc__ struct $gt_name <:
                                                     YaoBlocks.ConstGate.ConstantGate{$N,$nlevel} end),
        )
    end
    push!(ex.args, :(@eval $__module__ Base.@__doc__ const $(name) = $(gt_name)()))
    return ex
end

function define_binding(__module__::Module, const_binding, type, expr)
    return quote
        @eval $__module__ begin
            const $const_binding = similar($expr, $type)
            if size($(const_binding), 1) != size($(const_binding), 2)
                throw(DimensionMismatch("Quantum Gates must be square matrix."))
            end
            copyto!($const_binding, $(expr))
        end
    end
end

function define_binding(__module__::Module, const_binding, expr)
    return quote
        @eval $__module__ begin
            const $const_binding = $(expr)
            if size($(const_binding), 1) != size($(const_binding), 2)
                throw(DimensionMismatch("Quantum Gates must be square matrix."))
            end
        end
    end
end

# forward instance to const gate type
YaoBlocks.mat(::Type{T}, ::GT) where {T,GT<:ConstantGate} = YaoBlocks.mat(T, GT)

function define_methods(__module__::Module, const_binding, name)
    gt_name = gatetype_name(name)
    return quote
        @eval $__module__ begin
            YaoBlocks.mat(::Type{eltype($const_binding)}, ::Type{$gt_name}) = $const_binding

            function YaoBlocks.mat(::Type{T}, ::Type{$gt_name}) where {T}
                src = YaoBlocks.mat(eltype($const_binding), $gt_name)
                dst = similar(src, T)
                copyto!(dst, src)
                return dst
            end

            function YaoBlocks.print_block(io::IO, ::$gt_name)
                print(io, $(QuoteNode(name)))
            end
        end # eval
    end # quote
end

function define_properties(__module__::Module, const_binding, name)
    gt_name = gatetype_name(name)
    function def(property)
        flag = gensym(:flag)
        return quote
            @eval $__module__ begin
                const $flag = YaoBlocks.$property($const_binding)
                YaoBlocks.$property(::$gt_name) = $flag
                YaoBlocks.$property(::Type{GT}) where {GT<:$gt_name} = $flag
            end
        end
    end

    ex = Expr(:block)
    for each in [:ishermitian, :isreflexive, :isunitary]
        push!(ex.args, def(each))
    end
    return ex
end
