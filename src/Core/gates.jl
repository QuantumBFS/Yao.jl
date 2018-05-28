include("basis.jl")
include("basic_gates.jl")

####################### Gate Utilities ######################
⊗ = kron
function superkron(num_bit::Int, gates::Vector{T}, locs::Vector{Int}) where T<:AbstractMatrix
    locs = num_bit - locs + 1
    order = sortperm(locs)
    _wrap_identity(gates[order], diff(vcat([0], locs[order], [num_bit+1])) - 1)
end

# kron, and wrap matrices with identities.
function _wrap_identity(data_list::Vector{T}, num_bit_list::Vector{Int}) where T<:AbstractMatrix
    length(num_bit_list) == length(data_list) + 1 || throw(ArgumentError())
    reduce((x,y)->x ⊗ y[1] ⊗ II(1<<y[2]), II(1 << num_bit_list[1]), zip(data_list, num_bit_list[2:end]))
end

###################### X, Y, Z Gates ######################
function xgate(num_bit::Int, bits::Ints)
    mask = bmask(bits...)
    norder = map(b->flip(b, mask) + 1, basis(num_bit))
    PermuteMultiply(norder, ones(1<<num_bit))
end

function ygate(num_bit::Int, bits::Ints)
    mask = bmask(bits...)
    norder = map(b->flip(b, mask) + 1, basis(num_bit))
    #vals = [-im*(-1)^reduce(+,takebit(b, bits)) for b in basis]
    #vals = mapreduce(bit->map(x->x==0?-im:im, takebit(basis, bit)), .*, bits)
    bss = basis(num_bit)
    vals = mapreduce(bit->map(b->im*(2*takebit(b, bit)-1.0), bss), .*, bits)
    PermuteMultiply(norder, vals)
end

function zgate(num_bit::Int, bits::Ints)
    #vals = [(-1)^reduce(+,takebit(b, bits)) for b in basis]
    bss = basis(num_bit)
    #vals = mapreduce(bit->1.-2.0.*takebit.(bss, bit), (x,y)->broadcast(*,x,y), bits)
    vals = mapreduce(bit->map(b->1-2.0*takebit(b, bit), bss), (x,y)->broadcast(*,x,y), bits)
    Diagonal(vals)
end

####################### Controlled Gates #######################
general_controlled_gates(num_bit::Int, projectors::Vector{Tp}, cbits::Vector{Int}, gates::Vector{Tg}, locs::Vector{Int}) where {Tg<:AbstractMatrix, Tp<:AbstractMatrix} = II(1<<num_bit) - superkron(num_bit, projectors, cbits) + superkron(num_bit, vcat(projectors, gates), vcat(cbits, locs))

#### C-X/Y/Z Gates
function cnotgate(num_bit::Int, b1::Int, b2::Int)
    mask = bmask(b1)
    db = b2-b1
    order = map(i->i ⊻ ((i & mask) << db) + 1, basis(num_bit))
    PermuteMultiply(order, ones(Int, 1<<num_bit))
end
# CNOT/CZ may be further accelerated.
function czgate(num_bit::Int, b1::Int, b2::Int)
    Diagonal(map(i->1-2.0*(takebit(i, b1) & takebit(i, b2)), basis(num_bit)))
end

# general multi-control single-gate
function controlled_U1(num_bit::Int, gate::PermuteMultiply{T}, cbits::Vector{Int}, b2::Int) where {T}
    vals = ones(T, 1<<num_bit)
    order = collect(1:1<<num_bit)
    mask = bmask(cbits...)
    mask2 = bmask(b2)
    for b in basis(num_bit)
        #if testall(b, mask)
        #    @inbounds vals[b+1] = gate.vals[gate.perm[1+takebit(b, b2)]]
        #    @inbounds order[b+1] = (gate.perm[1] == 1) ? b+1: flip(b, mask2)+1
        #end
        if testall(b, mask)
            @inbounds vals[b+1] = gate.vals[gate.perm[1+takebit(b, b2)]]
            @inbounds order[b+1] = (gate.perm[1] == 1) ? b+1: flip(b, mask2)+1
        end
    end
    PermuteMultiply(order, vals)
end

function controlled_U1(num_bit::Int, gate::SparseMatrixCSC, b1::Vector{Int}, b2::Int)
    general_controlled_gates(2, [P1], [b1], [gate], [b2])
end

function controlled_U1(num_bit::Int, gate::Diagonal{T}, cbits::Vector{Int}, b2::Int) where {T}
    vals = ones(T, 1<<num_bit)
    mask = bmask(cbits...)
    a, b = gate.diag
    b_a = b-a
    disp = b2-1
    for i in basis(num_bit)
        #if testall(i, mask)
        #    @inbounds vals[i+1] = gate.diag[1+takebit(i, b2)]
        #end
        vals[i+1] = (b_a*takebit(i, b2))*testall(i, mask)
    end
    #vals = map(i->testall(i, mask)?a+b_a*takebit(i, b2):1, basis(num_bit))
    Diagonal(vals)
end
function controlled_U1(num_bit::Int, gate::StridedMatrix, b1::Vector{Int}, b2::Int)
    general_controlled_gates(2, [P1], [b1], [gate], [b2])
end

############################ Single Qubit Gates ################################
# arbitrary off-diagonal single qubit gate
# e.g. X, Y
function ndiaggate(num_bit::Int, gate::PermuteMultiply, bits::Ints)
end

# arbitrary diagonal single qubit gate
# e.g. Z, Rz(θ)
function diaggate(num_bit::Int, gate::Diagonal, bits::Ints)
end

# arbituary control PermuteMultiply gate: SparseMatrixCSC


# shortcuts
rxgate(θ::Float64, bit::Int, basis::Vector{DInt}) = nothing

toffoligate(num_bit::Int, b1::Int, b2::Int, b3::Int) = controlled_U1(num_bit, PAULI_X, [b1, b2], b3)
