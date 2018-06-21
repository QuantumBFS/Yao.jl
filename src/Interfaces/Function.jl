export @fn, InvOrder, addbit, Reset

macro fn(f)
    :(FunctionBlock($(esc(f))))
end

macro fn(name::Symbol, f)
    FT = FunctionBlock{name}
    :($FT($(esc(f))))
end

"""
    macro fn([name,] f)

Define a in-place function on a register inside circuits.
"""
:(@fn)

"""
    InvOrder

Return a [`FunctionBlock`](@ref) of inversing the order.
"""
const InvOrder = @fn InvOrder invorder!

"""
    Reset
"""
const Reset = @fn Reset reset!


"""
    addbit(n::Int) -> FunctionBlock{:AddBit}

Return a [`FunctionBlock`](@ref) of adding n bits.
"""
addbit(n::Int) = FunctionBlock{Tuple{:AddBit, n}}(reg->addbit!(reg, n))
