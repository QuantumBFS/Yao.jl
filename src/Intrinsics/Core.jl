# gates.jl
export general_controlled_gates, hilbertkron
export xgate, ygate, zgate
export cxgate, cygate, czgate
export controlled_U1

"""
    general_controlled_gates(num_bit::Int, projectors::Vector{Tp}, cbits::Vector{Int}, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix

Return general multi-controlled gates in hilbert space of `num_bit` qubits,

* `projectors` are often chosen as `P0` and `P1` for inverse-Control and Control at specific position.
* `cbits` should have the same length as `projectors`, specifing the controling positions.
* `gates` are a list of controlled single qubit gates.
* `locs` should have the same length as `gates`, specifing the gates positions.
"""
function general_controlled_gates end

"""
    hilbertkron(num_bit::Int, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix

Return general kronecher product form of gates in Hilbert space of `num_bit` qubits.

* `gates` are a list of single qubit gates.
* `locs` should have the same length as `gates`, specifing the gates positions.
"""
function hilbertkron end

"""
    xgate(::Type{MT}, num_bit::Int, bits::Ints) -> PermMatrix

X Gate on multiple bits.
"""
function xgate end

"""
    ygate(::Type{MT}, num_bit::Int, bits::Ints) -> PermMatrix

Y Gate on multiple bits.
"""
function ygate end

"""
    zgate(::Type{MT}, num_bit::Int, bits::Ints) -> Diagonal

Z Gate on multiple bits.
"""
function zgate end

"""
    cxgate(::Type{MT}, num_bit::Int, b1::Ints, b2::Ints) -> PermMatrix

Single (Multiple) Controlled-X Gate on single (multiple) bits.
"""
function cxgate end

"""
    cygate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) -> PermMatrix

Single Controlled-Y Gate on single bit.
"""
function cygate end

"""
    czgate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) -> Diagonal

Single Controlled-Z Gate on single bit.
"""
function czgate end

"""
    controlled_U1(num_bit::Int, gate::AbstractMatrix, cbits::Vector{Int}, b2::Int) -> AbstractMatrix

Return general multi-controlled single qubit `gate` in hilbert space of `num_bit` qubits.

* `cbits` specify the controling positions.
* `b2` is the controlled position.
"""
function controlled_U1 end
