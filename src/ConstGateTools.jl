module ConstGateTools

using MacroTools, LuxurySparse

using YaoBase
using YaoBase.Math

const DefaultType = ComplexF64
import ..YaoBlockTree
import ..YaoBlockTree: PrimitiveBlock, ConstantGate, mat, print_block

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
    gt_name = gatetype_name(name)

    quote
        # check if this symbol is used.
        if @isdefined $(name)
            @warn $msg
            false
        else
            @eval YaoBlockTree begin
                export $name, $gt_name
                # define a new constant gate type
                N = YaoBase.Math.log2i(size($(const_binding), 1))
                struct $gt_name{T} <: ConstantGate{N, T} end

                # define binding
                const $(name) = $(gt_name){$DefaultType}()
            end

            # printings
            $(define_printing(name))
            true
        end
    end

end # define_struct

function define_printing(name)
    gt_name = gatetype_name(name)
    msg = string(name)

    quote
        @eval YaoBlockTree begin
            function print_block(io::IO, ::$(gt_name))
                print(io, $(msg), " gate")
            end
            #tokenof(::Type{<:$(gt_name)}) = $(msg)
        end
    end
end

function define_property_trait(f, property, name, const_name)
    gt_name = gatetype_name(name)
    flag = gensym(:flag)
    property_name = :(YaoBlockTree.$property)

    quote
        @eval YaoBlockTree begin
            const $flag = $(f(const_name))
            $(property_name)(::Type{GT}) where {GT <: $(gt_name)} = $flag
            $(property_name)(::GT) where {GT <: $(gt_name)} = $flag
        end
    end
end

function define_traits(name, binding)
    quote
        $(define_property_trait(x->:(YaoBase.isreflexive($x)), :isreflexive, name, binding))
        $(define_property_trait(x->:(YaoBase.ishermitian($x)), :ishermitian, name, binding))
        $(define_property_trait(x->:(YaoBase.isunitary($x)), :isunitary, name, binding))
    end
end

function define_matrix_methods(name, binding, elt)
    gt_name = gatetype_name(name)

    quote
        @eval YaoBlockTree begin
            mat(::Type{$(gt_name){$elt}}) = $(binding)
            mat(::Type{$(gt_name)}) = mat($(gt_name){$DefaultType})
            mat(::GT) where {GT <: $(gt_name)} = mat(GT)

            function mat(::Type{$(gt_name){T}}) where {T <: Complex}
                src = mat($(gt_name){$elt})
                dest = Base.similar(src, T)
                copyto!(dest, src)
                dest
            end
        end
    end
end

#=
function define_callables(name)
    gt_name = gatetype_name(name)

    quote
        @eval YaoBlockTree begin
            # factory methods
            (::$(gt_name))() = $(gt_name){$DefaultType}()
            (::$(gt_name))(::Type{T}) where {T <: Complex} = $(gt_name){T}()

            # forward to apply! if the first arg is a register
            (gate::$(gt_name))(r::AbstractRegister, params...) = YaoBlockTree.apply!(r, gate, params...)

            # define shortcuts
            (gate::$(gt_name))(itr) = RangedBlock(gate, itr)
            # TODO: use Repeated instead
            (gate::$(gt_name))(n::Int, itr) = KronBlock{n}(i=>$name for i in itr)
        end
    end
end
=#

function define_methods(name, binding, t)
    quote
        #$(define_callables(name))
        $(define_matrix_methods(name, binding, t))
        $(define_traits(name, binding))
    end
end

# Entries

constant_name(name) = gensym(Symbol("Const", "_", name))

function bind_constant(const_binding, name, t, ex)
    quote
        @eval YaoBlockTree begin
            const $(const_binding) = Base.similar($(ex), $t)

            if size($(const_binding), 1) != size($(const_binding), 2)
                throw(DimensionMismatch("Quantum Gates must be square matrix."))
            end

            copyto!($(const_binding), $(ex))
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
        $(bind_constant(const_binding, name, DefaultType, ex))
        is_successed = $(define_struct(const_binding, name))

        if is_successed
            $(define_methods(name, const_binding, DefaultType))
        end
    end
end

function define_typed_binding(name, t)
    const_binding = constant_name(name)
    gt_name = gatetype_name(name)

    quote
        if @isdefined $(name)
            throw($(UndefVarError(name)))
        end

        @eval YaoBlockTree begin
            const $(const_binding) = mat($(gt_name){$t})
            mat(::Type{$(gt_name){$t}}) = $(const_binding)
        end
    end
end

end
