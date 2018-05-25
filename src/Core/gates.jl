include("basis.jl")
include("permmul.jl")

function xgate(bits::Ints, basis::Vector{DInt})
    norder = flip(basis, bits)
    PermuteMultiply(norder+1, ones(length(basis)))
end

function ygate(bits::Ints, basis::Vector{DInt})
    norder = flip(basis, bits)
    #vals = [-im*(-1)^reduce(+,takebit(b, bits)) for b in basis]
    #vals = mapreduce(bit->map(x->x==0?-im:im, takebit(basis, bit)), .*, bits)
    vals = mapreduce(bit->im.*(2.*takebit(basis, bit).-1), .*, bits)
    PermuteMultiply(norder+1, vals)
end

function zgate(bits::Ints, basis::Vector{DInt})
    #vals = [(-1)^reduce(+,takebit(b, bits)) for b in basis]
    vals = mapreduce(bit->1.-2.*takebit(basis, bit), .*, bits)
    PermuteMultiply(basis+1, vals)
end

############################ TODO ################################
# arbitrary off-diagonal single qubit gate
# e.g. X, Y, p↑, p↓
function ndiaggate(gate::PermuteMultiply, bits::Ints, basis::Vector{DInt})
    norder = flip(basis, bits)
    vals = mapreduce(bit->exp.(im*phi*(2.*takebit(basis, bit).-1)), .*, bits)
    PermuteMultiply(norder+1, vals)
end

# arbitrary diagonal single qubit gate
# e.g. Z, Rz(θ), p0, p1
function diaggate(gate::Diagonal, bits::Ints, basis::Vector{DInt})
    vals = mapreduce(bit->exp.(im*phi*(2.*takebit(basis, bit).-1)), .*, bits)
    PermuteMultiply(basis+1, vals) # or Diagonal(vals) ?
end

#TODO
# arbituary dense single qubit gate: SparseMatrixCSC
# e.g. Rx(θ), Ry(θ), Rot(θ1,θ2,θ3)
function densegate(bits::Ints, basis::Vector{DInt})
end

# arbituary control PermuteMultiply gate: SparseMatrixCSC


# shortcuts
rxgate(θ::Float64, bit::Int, basis::Vector{DInt}) = nothing
