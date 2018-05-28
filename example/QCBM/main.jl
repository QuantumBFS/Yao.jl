using QuCircuit
using MacroTools

macro const_gate2(ex)
    if @capture(ex, NAME_::TYPE_ = EXPR_)
        println(NAME, TYPE)
    elseif @capture(ex, NAME_ = EXPR_)
        println(NAME)
    end
end

@const_gate2 X::Complex128 = [0 1;1 0]
