import YaoBlocks.YaoBase.LegibleLambdas: LegibleLambda, @λ
export MathGate, mathgate

struct MathGate{N, F <: Union{LegibleLambda, Function}} <: PrimitiveBlock{N}
    f::F
end

function MathGate{N}(f::Union{LegibleLambda, Function}) where N
    return MathGate{N, typeof(f)}(f)
end

"""
    mathgate(nbits, f)

Create a [`MathGate`](@ref) with a math function `f` and number of bits.

    mathgate(f) -> f(n)

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

julia> g = mathgate(3, toffli)
mathgate(toffli; nbits=3)

julia> apply!(r, g) == ArrayReg(bit"111")
true

```
"""
mathgate(nbits::Int, f) = MathGate{nbits}(f)
mathgate(f::Union{LegibleLambda, Function}) = @λ(nbits->matgate(nbits, f))

function _apply!(r::ArrayReg, m::MathGate{N, F}) where {N, F}
    nstate = zero(r.state)
    for b in basis(BitStr64{N})
        b2 = m.f(b)
        nstate[Int64(b2)+1, :] = view(r.state, Int64(b)+1, :)
    end
    r.state .= nstate
    return r
end

# TODO: use trait to correct this
function YaoAPI.mat(::Type{T}, m::MathGate{N}) where {T, N}
    L = 1<<N
    vals = zeros(T, L)
    perm = zeros(Int, L)
    for b in basis(BitStr64{N})
        b2 = m.f(b)
        vals[Int64(b2)+1] += 1
        perm[Int64(b2)+1] = Int64(b) + 1
    end
    any(==(0), vals) && throw(ArgumentError("This `MathGate` is not unitary! Failed converting to a `PermMatrix`! maybe use `applymatrix` to check your block?"))
    return PermMatrix(perm, vals)
end
