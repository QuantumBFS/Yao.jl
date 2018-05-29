# 1. primitive blocks

# 1.2 phase gate
# 1.2.1 global phase
export phase
phase(::Type{T}, theta) where {T <: Complex} = PhaseGate{:global, real(T)}(theta)
phase(theta=0.0) = phase(CircuitDefaultType, theta)

# 1.2.2 phase shift
export shift
shift(::Type{T}, theta) where {T <: Complex} = PhaseGate{:shift, real(T)}(theta)
shift(theta=0.0) = shift(CircuitDefaultType, theta)

# 1.3 rotation gate
export Rx, Ry, Rz, rot

for (FNAME, NAME) in [
    (:Rx, :X),
    (:Ry, :Y),
    (:Rz, :Z),
]

    GT = Symbol(join([NAME, "Gate"]))
    @eval begin
        $FNAME(::Type{T}, theta=0.0) where {T <: Complex} = RotationGate{real(T), $GT{T}}($NAME(T), theta)
        $FNAME(theta=0.0) = $FNAME(CircuitDefaultType, theta)
    end

end

rot(::Type{T}, U::GT, theta=0.0) where {T, GT} = RotationGate{real(T), GT}(U, theta)
rot(U::MatrixBlock, theta=0.0) = rot(CircuitDefaultType, U, theta)
