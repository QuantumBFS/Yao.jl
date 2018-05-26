mutable struct RotationGate{GT, T} <: PrimitiveBlock{1, Complex{T}}
    theta::T

    function RotationGate{GT}(theta::T) where {GT, T}
        new{GT, T}(theta)
    end

    function RotationGate(x::Symbol, theta::T) where T
        new{Val{x}, T}(theta)
    end
end

_make_rot_mat(I, U, theta) = I * cos(theta / 2) - im * sin(theta / 2) * U
mat(R::RotationGate{GT, T}) where {GT, T} = _make_rot_mat(Const.Dense.I2(Complex{T}), full(gate(Complex{T}, GT)), R.theta)

copy(block::RotationGate{GT}) where GT = RotationGate{GT}(block.theta)

function dispatch!(f::Function, block::RotationGate{GT}, theta) where {GT}
    block.theta = f(block.theta, theta)
    block
end

# Properties
nparameters(::RotationGate) = 1

##################
# Pretty Printing
##################

for (GTYPE, NAME) in [
    (:X, "Rx"),
    (:Y, "Ry"),
    (:Z, "Rz"),
]

    GT = Val{GTYPE}

    @eval begin
        function show(io::IO, g::RotationGate{$GT, T}) where T
            print(io, $NAME, "{", T, "}: ", g.theta)
        end
    end

end
