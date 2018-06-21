export @functor, InvOrder, addbit, Reset

"""
    macro functor([tag,] apply)

Turn a function into a Functor{tag} block, this function take register as input,
modify and output the register.
"""

macro functor(apply)
    :(Functor($apply))
end

macro functor(tag::Symbol, apply)
    local TP = Functor{tag}
    :($TP($apply))
end

"""
A Functor block of inversing the order.
"""
InvOrder = @functor InvOrder invorder!

"""
    addbit(n::Int) -> Functor{:AddBit}

Return a Functor block of adding n bits.
"""
addbit(n::Int) = Functor{:AddBit}(reg->addbit!(reg, n))
Reset = Functor{:RESET}(reset!)
