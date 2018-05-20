mutable struct RotationGate{GT, T} <: PrimitiveBlock{1, Complex{T}}
    theta::T
end

# TODO: implement arbitrary rotation: cos(theta/2) - im * sin(theta/2) * U

sparse(gate::RotationGate) = sparse(full(gate))

full(gate::RotationGate{GateType{:X}, T}) where T =
    Complex{T}[cos(gate.theta/2) -im*sin(gate.theta/2);
      -im*sin(gate.theta/2) cos(gate.theta/2)]
full(gate::RotationGate{GateType{:Y}, T}) where T =
    Complex{T}[cos(gate.theta/2) -sin(gate.theta/2);
      sin(gate.theta/2) cos(gate.theta/2)]
full(gate::RotationGate{GateType{:Z}, T}) where T =
    Complex{T}[exp(-im*gate.theta/2) 0;0 exp(im*gate.theta/2)]

copy(block::RotationGate{GT, T}) where {GT, T} = RotationGate{GT, T}(block.theta)

# TODO: dispatch a vector
dispatch!(block::RotationGate{GT, T}, theta::T) where {GT, T} = (block.theta = theta; block)
dispatch!(f::Function, block::RotationGate{GT, T}, theta::T) where {GT, T} = (block.theta = f(block.theta, theta); block)

function dispatch!(block::RotationGate, theta::Vector)
    block.theta = pop!(theta)
    block
end

function dispatch!(f::Function, block::RotationGate, theta::Vector)
    block.theta = f(block.theta, pop!(theta))
    block
end

##################
# Pretty Printing
##################

for (GTYPE, NAME) in [
    (:X, "Rx"),
    (:Y, "Ry"),
    (:Z, "Rz"),
]

    GT = GateType{GTYPE}

    @eval begin
        function show(io::IO, g::RotationGate{$GT, T}) where T
            print(io, $NAME, "{", T, "}: ", g.theta)
        end
    end

end
