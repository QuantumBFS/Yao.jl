*(::XGate, ::YGate) = im*Z
*(::XGate, ::ZGate) = -im*Y
*(::YGate, ::XGate) = -im*Z
*(::YGate, ::ZGate) = im*X
*(::ZGate, ::XGate) = im*Y
*(::ZGate, ::YGate) = -im*X

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
