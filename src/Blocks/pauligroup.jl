*(::XGate, ::YGate) = Im(Z)
*(::XGate, ::ZGate) = _Im(Y)
*(::YGate, ::XGate) = _Im(Z)
*(::YGate, ::ZGate) = Im(X)
*(::ZGate, ::XGate) = Im(Y)
*(::ZGate, ::YGate) = _Im(X)

for G in [:XGate, :YGate, :ZGate]
    @eval *(g::$G, ::I2Gate) = g
    @eval *(::I2Gate, g::$G) = g
    @eval *(g1::$G, g2::$G) = I2
end
*(g1::I2Gate, g2::I2Gate) = I2

tokenof(::Type{<:I2Gate}) = :I₂
tokenof(::Type{<:XGate}) = :σˣ
tokenof(::Type{<:YGate}) = :σʸ
tokenof(::Type{<:ZGate}) = :σᶻ
