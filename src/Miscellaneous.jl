export inverselines, singlet_block

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

function singlet_block(::Type{T}, nbit::Int, i::Int, j::Int) where T
    unit = chain(nbit)
    push!(unit, put(nbit, i=>chain(XGate{T}(), HGate{T}())))
    push!(unit, control(nbit, -i, j=>XGate{T}()))
end

singlet_block(nbit::Int, i::Int, j::Int) = singlet_block(ComplexF64, nbit, i, j)
singlet_block() = singlet_block(2,1,2)

Yao.mat(ρ::DensityMatrix{1}) = dropdims(state(ρ), dims=3)
