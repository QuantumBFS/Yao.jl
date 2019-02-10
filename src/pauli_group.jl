Base.:*(::XGate, ::YGate) = Im(Z)
Base.:*(::XGate, ::ZGate) = _Im(Y)
Base.:*(::YGate, ::XGate) = _Im(Z)
Base.:*(::YGate, ::ZGate) = Im(X)
Base.:*(::ZGate, ::XGate) = Im(Y)
Base.:*(::ZGate, ::YGate) = _Im(X)

for G in [:XGate, :YGate, :ZGate]
    @eval Base.:*(g::$G, ::I2Gate) = g
    @eval Base.:*(::I2Gate, g::$G) = g
    @eval Base.:*(g1::$G, g2::$G) = I2
end

Base.:*(g1::I2Gate, g2::I2Gate) = I2

tokenof(::Type{<:I2Gate}) = :I₂
tokenof(::Type{<:XGate}) = :σˣ
tokenof(::Type{<:YGate}) = :σʸ
tokenof(::Type{<:ZGate}) = :σᶻ
