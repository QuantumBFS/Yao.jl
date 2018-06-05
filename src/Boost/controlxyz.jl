####################### Controlled Gates #######################
bmask() = DInt(0)
#### C-X/Y/Z Gates
function cxgate(::Type{MT}, num_bit::Int, cbits::Vector{Int}, cvals::Vector{Int}, b2::Ints) where MT<:Number
    mask = bmask(cbits...)
    onemask = bmask(cbits[cvals.==1]...)
    mask2 = bmask(b2)
    order = map(i->testval(i, mask, onemask) ? flip(i, mask2)+1 : i+1, basis(num_bit))
    PermuteMultiply(order, ones(MT, 1<<num_bit))
end

function cygate(::Type{MT}, num_bit::Int, cbits::Vector{Int}, cvals::Vector{Int}, b2::Int) where MT<:Complex
    mask = bmask(cbits...)
    onemask = bmask(cbits[cvals.==1]...)
    mask2 = bmask(b2)
    order = Vector{Int}(1<<num_bit)
    vals = Vector{MT}(1<<num_bit)
    @simd for b = 0:1<<num_bit-1
        i = b+1
        if testval(b, mask, onemask)
            @inbounds order[i] = flip(b, mask2) + 1
            @inbounds vals[i] = testany(b, mask2) ? MT(im) : -MT(im)
        else
            @inbounds order[i] = i
            @inbounds vals[i] = MT(1)
        end
    end
    PermuteMultiply(order, vals)
end

function czgate(::Type{MT}, num_bit::Int, cbits::Vector{Int}, cvals::Vector{Int}, b2::Int) where MT<:Number
    mask = bmask(cbits..., b2)
    onemask = bmask(cbits[cvals.==1]..., b2)
    vals = map(i->testval(i, mask, onemask) ? MT(-1) : MT(1), basis(num_bit))
    Diagonal(vals)
end


# general multi-control single-gate
function controlled_U1(num_bit::Int, gate::PermuteMultiply{T}, cbits::Vector{Int}, cvals::Vector{Int}, b2::Int) where {T}
    vals = Vector{T}(1<<num_bit)
    order = Vector{Int}(1<<num_bit)
    mask = bmask(cbits...)
    onemask = bmask(cbits[cvals.==1]...)
    mask2 = bmask(b2)
    @simd for b in basis(num_bit)
        bind = b+1
        if testval(b, mask, onemask)
            @inbounds vals[bind] = gate.vals[gate.perm[2-takebit(b, b2)]]
            @inbounds order[bind] = (gate.perm[1] == 1) ? bind : flip(b, mask2)+1
        else
            @inbounds vals[bind] = 1
            @inbounds order[bind] = bind
        end
    end
    PermuteMultiply(order, vals)
end

function controlled_U1(num_bit::Int, gate::Diagonal{T}, cbits::Vector{Int}, cvals::Vector{Int}, b2::Int) where {T}
    mask = bmask(cbits...)
    mask2 = bmask(b2)
    onemask = bmask(cbits[cvals.==1]...)
    
    a, b = gate.diag
    ######### LW's version ###########
    vals = Vector{T}(1<<num_bit)
    @simd for i in basis(num_bit)
        if testval(i, mask, onemask)
            @inbounds vals[i+1] = gate.diag[1+takebit(i, b2)]
        else
            @inbounds vals[i+1] = 1
        end
    end
    Diagonal(vals)
end

function controlled_U1(num_bit::Int, gate::AbstractMatrix, cbits::Vector{Int}, cvals::Vector{Int}, b2::Int)
    general_controlled_gates(num_bit, [c==1 ? P1 : P0 for c in cvals], cbits, [gate], [b2])
end

using Compat.Test
using BenchmarkTools
@test cxgate(Complex128, 2, [2], [1], 1) == [1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0] == controlled_U1(2, Matrix(PAULI_X), [2], [1], 1) 
@test cxgate(Complex128, 2, [2], [0], 1) == [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1] == controlled_U1(2, Matrix(PAULI_X), [2], [0], 1) 
@test czgate(Complex128, 2, [1], [1], 2) == [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 -1] == controlled_U1(2, PAULI_Z, [2], [1], 1) 
@test general_controlled_gates(3, [P1], [3], [PAULI_Y], [2]) == controlled_U1(3, PAULI_Y, [3], [1], 2) == cygate(Complex128, 3, [3], [1], 2)

#@benchmark czgate(Complex128,16, [3], [1], 7)
#@code_warntype controlled_U1(16, (sparse(PAULI_Z)), [3], [1], 7)
#@benchmark controlled_U1(16, $(sparse(PAULI_Z)), [3], [1], 7)
#@benchmark general_controlled_gates(16, [P1], [7], [PAULI_Z], [3])

#@benchmark cxgate(Complex128,16, [7], [1], 3)
#@benchmark controlled_U1(16, PAULI_X, [3], [1], 7)
#@benchmark general_controlled_gates(16, [P1], [7], [PAULI_X], [3])

#@code_warntype czgate(Complex128,16, [7], [1], 3)
#@benchmark cygate(Complex128,16, [7], [1], 3)
#@benchmark controlled_U1(16, PAULI_Y, [3], [1], 7)
#@benchmark general_controlled_gates(16, [P1], [7], [PAULI_Y], [3])
