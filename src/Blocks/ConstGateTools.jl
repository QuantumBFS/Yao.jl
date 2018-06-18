module ConstGateTools

using Compat
using MacroTools

using ..Registers
using ..LuxurySparse

import ..Yao
import ..Blocks
import ..Blocks: PrimitiveBlock, ConstantGate, DefaultType, log2i, mat, print_block

export @const_gate

"""
    @const_gate NAME = MAT_EXPR
    @const_gate NAME::Type = MAT_EXPR
    @const_Gate NAME::Type

This macro simplify the definition of a constant gate. It will automatically bind the matrix form
to a constant which will reduce memory allocation in the runtime.

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
macro const_gate(ex)
    if @capture(ex, NAME_::TYPE_ = EXPR_)
        define_gate(NAME, TYPE, EXPR)
    elseif @capture(ex, NAME_ = EXPR_)
        define_gate(NAME, EXPR)
    elseif @capture(ex, NAME_::TYPE_)
        define_typed_binding(NAME, TYPE)
    else
        throw(MethodError(Symbol("@const_gate"), ex))
    end
end

gatetype_name(name) = Symbol(name, "Gate")

###########################
# Define Struct
###########################

function define_struct(const_binding, name)

    msg = "$(string(name)) is already defined, check if your desired name is available."
    # check if this symbol is used.
@static if VERSION < v"0.7-"
    if isdefined(name)
        return :(
            Compat.@warn($msg); false
        )
    end
else
    if @isdefined(name)
        return :(
            Compat.@warn($msg); false
        )
    end
end

gt_name = gatetype_name(name)

quote
    @eval begin
        # define a new constant gate type
        N = log2i(size($(const_binding), 1))
        struct $gt_name{T} <: ConstantGate{N, T} end

        # define binding
        const $(esc(name)) = $(esc(gt_name)){$DefaultType}()
    end

    # printings
    $(define_printing(name))
    true
end

end # define_struct

function define_printing(name)
    gt_name = gatetype_name(name)
    msg = string(name)

    quote
        @eval begin
            function $(esc(:(Yao.Blocks.print_block)))(io::IO, ::$(esc(gt_name)))
                print(io, $(msg), " gate")
            end
        end
    end
end

function define_property_trait(f, property, name, const_name)
    gt_name = gatetype_name(name)
    flag = gensym(:flag)
    property_name = :(Blocks.$property)

    quote
        @eval begin
            const $flag = $(f(const_name))
            $(esc(property_name))(::Type{GT}) where {GT <: $(esc(gt_name))} = $flag
            $(esc(property_name))(::GT) where {GT <: $(esc(gt_name))} = $flag
        end
    end
end

function define_traits(name, binding)
    quote
        $(define_property_trait(x->:(Yao.Intrinsics.isreflexive($x)), :isreflexive, name, binding))
        $(define_property_trait(x->:(Yao.Intrinsics.ishermitian($x)), :ishermitian, name, binding))
        $(define_property_trait(x->:(Yao.Intrinsics.isunitary($x)), :isunitary, name, binding))
    end
end

function define_matrix_methods(name, binding, elt)
    gt_name = gatetype_name(name)

    quote
        @eval begin
            $(esc(:(Yao.Blocks.mat)))(::Type{$(esc(gt_name)){$elt}}) = $(binding)
            $(esc(:(Yao.Blocks.mat)))(::Type{$(esc(gt_name))}) = $(esc(:mat))($(esc(gt_name)){$DefaultType})
            $(esc(:(Yao.Blocks.mat)))(::GT) where {GT <: $(esc(gt_name))} = $(esc(:mat))(GT)

            function $(esc(:(Yao.Blocks.mat)))(::Type{$(esc(gt_name)){T}}) where {T <: Complex}
                src = mat($(esc(gt_name)){$elt})
                dest = similar(src, T)
                copyto!(dest, src)
                dest
            end
        end
    end
end

function define_callables(name)
    gt_name = gatetype_name(name)

    quote
        @eval begin
            # factory methods
            (::$(esc(gt_name)))() = $(esc(gt_name)){$DefaultType}()
            (::$(esc(gt_name)))(::Type{T}) where {T <: Complex} = $(esc(gt_name)){T}()
        end
    end
end

function define_methods(name, binding, t)
    quote
        $(define_callables(name))
        $(define_matrix_methods(name, binding, t))
        $(define_traits(name, binding))
    end
end

# Entries

@static if VERSION < v"0.7-"
    constant_name(name) = esc(gensym(Symbol("Const", "_", name)))
else
    constant_name(name) = gensym(Symbol("Const", "_", name))
end

function bind_constant(const_binding, name, t, ex)
    quote
        @eval begin
            const $(const_binding) = similar($(esc(ex)), $t)

            if size($(const_binding), 1) != size($(const_binding), 2)
                throw(DimensionMismatch("Quantum Gates must be square matrix."))
            end

            copyto!($(const_binding), $(esc(ex)))
        end
    end
end

function define_gate(name, t, ex)
    const_binding = constant_name(name)
    gt_name = gatetype_name(name)

    quote
        $(bind_constant(const_binding, name, t, ex))
        is_successed = $(define_struct(const_binding, name))

        if is_successed
            $(define_methods(name, const_binding, t))
        end
    end
end

function define_gate(name, ex)
    const_binding = constant_name(name)
    gt_name = gatetype_name(name)

    quote
        $(bind_constant(const_binding, name, :DefaultType, ex))
        is_successed = $(define_struct(const_binding, name))

        if is_successed
            $(define_methods(name, const_binding, :DefaultType))
        end
    end
end

function define_typed_binding(name, t)
    const_binding = constant_name(name)
    gt_name = gatetype_name(name)

    quote
        if $(!isdefined(name))
            throw($(UndefVarError(name)))
        end

        @eval begin
            const $(const_binding) = mat($(esc(gt_name)){$t})
            $(esc(:(Yao.Blocks.mat)))(::Type{$(esc(gt_name)){$t}}) = $(const_binding)
        end
    end
end

end
