export FunctionBlock

"""
    FunctionBlock <: AbstractBlock

This block contains a general function that perform an in-place operation over a register
"""
struct FunctionBlock{FT} <: AbstractBlock
    apply!
    function FunctionBlock{FT}(f) where FT
        !isempty(methods(f)) || throw(ArgumentError("Input is not callable!"))
        new{FT}(f)
    end
end

FunctionBlock(f) = FunctionBlock{typeof(f)}(f)
apply!(reg::AbstractRegister, f::FunctionBlock) = f.apply!(reg)
