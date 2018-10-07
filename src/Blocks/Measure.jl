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

mutable struct Measure <: AbstractMeasure
    result::Vector{Int}
    Measure() = new()
end

mutable struct MeasureAndRemove <: AbstractMeasure
    result::Vector{Int}
    MeasureAndRemove() = new()
end

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
    @eval function print_block(io::IO, pb::$BT)
        printstyled(io, "$BT"; bold=true, color=:red)
    end
end
