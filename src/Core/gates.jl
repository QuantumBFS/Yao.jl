include("basis.jl")
include("permmul.jl")

function xgate(num_bit::Int, bits::Ints)
    mask = bmask(bits...)
    norder = flip.(basis(num_bit), mask) .+ 1
    PermuteMultiply(norder, ones(1<<num_bit))
end

function ygate(num_bit::Int, bits::Ints)
    mask = bmask(bits...)
    @views norder = flip.(basis(num_bit), mask) .+ 1
    #vals = [-im*(-1)^reduce(+,takebit(b, bits)) for b in basis]
    #vals = mapreduce(bit->map(x->x==0?-im:im, takebit(basis, bit)), .*, bits)
    vals = mapreduce(bit->im.*(2.*takebit.(basis(num_bit), bit).-1), .*, bits)
    PermuteMultiply(norder, vals)
end

function zgate(num_bit::Int, bits::Ints)
    #vals = [(-1)^reduce(+,takebit(b, bits)) for b in basis]
    bss = basis(num_bit)
    vals = mapreduce(bit->1.-2.*takebit.(bss, bit), (x,y)->broadcast(*,x,y), bits)
    Diagonal(vals)
end

############################ TODO ################################
# arbitrary off-diagonal single qubit gate
# e.g. X, Y
function ndiaggate(num_bit::Int, gate::PermuteMultiply, bits::Ints)
    norder = flip(basis(num_bit), bits)
    vals = mapreduce(bit->exp.(im*phi*(2.*takebit(basis(num_bit), bit).-1)), .*, bits)
    PermuteMultiply(norder+1, vals)
end

# arbitrary diagonal single qubit gate
# e.g. Z, Rz(θ)
function diaggate(num_bit::Int, gate::Diagonal, bits::Ints)
    vals = mapreduce(bit->exp.(im*phi*(2.*takebit(basis(num_bit), bit).-1)), .*, bits)
    PermuteMultiply(basis(num_bit)+1, vals) # or Diagonal(vals) ?
end

# arbituary control PermuteMultiply gate: SparseMatrixCSC


# shortcuts
rxgate(θ::Float64, bit::Int, basis::Vector{DInt}) = nothing
