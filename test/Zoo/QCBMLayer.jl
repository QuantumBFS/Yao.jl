using QuCircuit
import QuCircuit: PrimitiveBlock

struct RotationLayer{N} <: PrimitiveBlock{N, Complex128}
    theta::Matrix{Complex128}
end


