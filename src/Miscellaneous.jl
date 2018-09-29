export inverselines

"""
    inverselines(nbit::Int; n_reg::Int=nbit) -> ChainBlock

inverse first `n_reg` lines

TODO:
deprecate this function, it is not used.
"""
function inverselines(nbit::Int; n_reg::Int=nbit)
    c = chain(nbit)
    for i = 1:(n_reg ÷ 2)
        push!(c, swap(i,(n_reg-i+1)))
    end
    c
end


