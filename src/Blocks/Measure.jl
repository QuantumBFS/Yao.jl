struct Measure{N, M} <: AbstractMeasure{N, M}
    lines::NTuple{M, Int}
end

function apply!(reg::Register{N}, block::Measure{N, M}) where {N, M}
end