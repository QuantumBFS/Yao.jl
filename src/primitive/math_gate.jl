using YaoBase, YaoArrayRegister, BitBasis
import LegibleLambdas: LegibleLambda, parse_lambda
export MathGate, mathgate, @mathgate

struct MathGate{N, F <: Union{LegibleLambda, Function}, Fv <: Function} <: PrimitiveBlock{N, Bool}
    f::F
    v::Fv
end

function MathGate{N}(f::Union{LegibleLambda, Function}; bview::Function=bint) where N
    return MathGate{N, typeof(f), typeof(bview)}(f, bview)
end

"""
    mathgate(f; nbits[, bview=BitBasis.bint])

Create a [`MathGate`](@ref) with a math function `f` and number of bits. You can
select different kinds of view which this `MathGate` will be applied on. Possible
values are [`BitBasis.bint`](@ref), [`BitBasis.bint_r`](@ref),
[`BitBasis.bfloat`](@ref), [`BitBasis.bfloat_r`](@ref).

    mathgate(f; bview=BitBasis.bint) -> f(n)

Lazy curried version of `mathgate`.

# Example

We can make a classical toffoli gate on quantum register.

```julia
julia> r = ArrayReg(bit"110")
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 3/3

julia> function toffli(b::BitStr)
           t = @inbounds b[1] ⊻ (b[3] & b[2])
           return @inbounds bit_literal(t, b[2], b[3])
       end
toffli (generic function with 1 method)

julia> g = mathgate(toffli; nbits=3)
mathgate(toffli; nbits=3, bview=bint)

julia> apply!(r, g) == ArrayReg(bit"111")
true

```
"""
function mathgate(f; nbits::Union{Int, Nothing}=nothing, bview::Function=bint)
    if nbits === nothing
        @λ(n->matgate(f; nbits=n, bview=bview))
    else
        return MathGate{nbits}(f; bview=bview)
    end
end

"""
    @mathgate f <nbits> <bview=bint>

Create a [`MathGate`](@ref) with a math function `f` and number of bits `nbits`,
binary view `bview`. Unlike [`mathgate`](@ref), `f` will be automatically
converted to a more legible form.

# Example

```jldoctest
julia> @mathgate x->x + 0b11 nbits=4
mathgate((x -> x + 0x03); nbits=4, bview=bint)
```
"""
:(@mathgate)

macro mathgate(f, nbits, bview)
    if !(nbits.head === :(=) && nbits.args[1] === :nbits)
        return :(error("expect keyword nbits, got $nbits"))
    end

    if !(bview.head === :(=) && bview.args[1] === :bview)
        return :(error("expect keyword bview, got $bview"))
    end

    return quote
        mathgate($(parse_lambda(f)); nbits=$(esc(nbits.args[2])), bview=$(esc(bview.args[2])))
    end
end

macro mathgate(f, nbits)
    if !(nbits.head === :(=) && nbits.args[1] === :nbits)
        return :(error("expect keyword nbits, got $nbits"))
    end

    return quote
        mathgate($(parse_lambda(f)); nbits=$(esc(nbits.args[2])))
    end
end

macro mathgate(f)
    return quote
        mathgate($(parse_lambda(f)))
    end
end

mathop(m::MathGate{N, F, typeof(bint)}, b::Int) where {N, F} = callmath(m)(b)

function callmath(m::MathGate{N}) where N
    @inline _value(x::BitStr) = x.val
    @inline _value(x) = x

    return function (x::T) where T
        if hasmethod(m.f, Tuple{T})
            return btruncate(m.f(x), N)
        elseif hasmethod(m.f, Tuple{T, typeof(N)})
            return m.f(x, N)
        elseif hasmethod(m.f, Tuple{BitStr{T, N}})
            return btruncate(_value(m.f(bit(x; len=N))), N)
        elseif hasmethod(m.f, Tuple{BitStr{T, N}, typeof(N)})
            return _value(m.f(bit(x; len=N), N))
        else
            error("Invalid math function call, math operation should be either f(x) or f(x, N::Int)")
        end
    end
end

function mathop(m::MathGate{N, F, typeof(bint_r)}, b::Int) where {N, F}
    return b |> x->bint_r(x; nbits=N) |> callmath(m) |> x->bint_r(x; nbits=N)
end

function mathop(m::MathGate{N, F, typeof(bfloat)}, b::Int) where {N, F}
    return b |> x->bfloat(x; nbits=N) |> callmath(m) |> x->bint(x; nbits=N)
end

function mathop(m::MathGate{N, F, typeof(bfloat_r)}, b::Int) where {N, F}
    return b |> x->bfloat_r(x; nbits=N) |> callmath(m) |> x->bint_r(x; nbits=N)
end

function apply!(r::ArrayReg, m::MathGate{N, F}) where {N, F}
    nstate = zero(r.state)
    for b in basis(r)
        b2 = mathop(m, b)
        nstate[b2+1, :] = view(r.state, b+1, :)
    end
    r.state = nstate
    return r
end

# TODO: use trait to correct this
mat(m::MathGate) = applymatrix(m)
