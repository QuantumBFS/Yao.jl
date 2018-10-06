export AbstractMeasure, Measure, MeasureAndRemove

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

function apply!(reg::AbstractRegister, block::Measure)
    samples = measure!(reg)
    block.result = samples
    reg
end

mutable struct MeasureAndRemove <: AbstractMeasure
    result::Vector{Int}
    MeasureAndRemove() = new()
end

function apply!(reg::AbstractRegister, block::MeasureAndRemove)
    samples = measure_remove!(reg)
    block.result = samples
    reg
end

function print_block(io::IO, pb::MeasureAndRemove)
    printstyled(io, "measure & remove"; bold=true, color=:red)
end

function print_block(io::IO, pb::Measure)
    printstyled(io, "measure"; bold=true, color=:red)
end
