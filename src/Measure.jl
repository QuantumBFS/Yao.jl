export AbstractMeasure, Measure, MeasureAndRemove, MeasureAndReset

"""
    AbstractMeasure <: AbstractBlock

Abstract block supertype which measurement block will inherit from.
"""
abstract type AbstractMeasure <: AbstractBlock end

#####################
# Measurement Blocks
#####################
abstract type AbstractMeasure <: AbstractBlock end

"""
    Measure <: AbstractMeasure
    Measure() -> Measure

Measure block, collapse a state and store measured value, e.g.

# Examples
```julia-repl
julia> m = Measure();

julia> reg = product_state(4, 7)
DenseRegister{1, Complex{Float64}}
    active qubits: 4/4

julia> reg |> m
DenseRegister{1, Complex{Float64}}
    active qubits: 4/4

julia> m.result
1-element Array{Int64,1}:
 7
```

Note:
`Measure` returns a vector here, the length corresponds to batch dimension of registers.
"""
mutable struct Measure <: AbstractMeasure
    result::Vector{Int}
    Measure() = new()
end

"""
    MeasureAndRemove <: AbstractMeasure
    MeasureAndRemove() -> MeasureAndRemove

Measure and remove block, remove measured qubits and store measured value.
"""
mutable struct MeasureAndRemove <: AbstractMeasure
    result::Vector{Int}
    MeasureAndRemove() = new()
end

"""
    MeasureAndReset <: AbstractMeasure
    MeasureAndReset([val=0]) -> MeasureAndReset

Measure and reset block, reset measured qubits to `val` and store measured value.
"""
mutable struct MeasureAndReset <: AbstractMeasure
    val::Int
    result::Vector{Int}
    MeasureAndReset(val::Int) = new(val)
end
MeasureAndReset() = MeasureAndReset(0)

for (BT, FUNC) in zip((:Measure, :MeasureAndRemove, :MeasureAndReset), (:measure!, :measure_remove!, :measure_reset!))
    APPLY_ON_REG = BT == :MeasureAndReset ? :($FUNC(reg, val=block.val)) : :($FUNC(reg))
    @eval function apply!(reg::AbstractRegister, block::$BT)
        samples = $APPLY_ON_REG
        block.result = samples
        reg
    end
    EXTRA = BT == :MeasureAndReset ? :(" -> $(pb.val)") : :("")
    @eval function print_block(io::IO, pb::$BT)
        printstyled(io, string($BT)*$EXTRA; bold=true, color=:red)
    end
end
