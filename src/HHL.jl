export hhlcircuit, hhlproject!, hhlsolve, HHLCRot

"""
    HHLCRot{N, NC} <: PrimitiveBlock{N}

Controlled rotation gate used in HHL algorithm, applied on N qubits.

    * cbits: control bits.
    * ibit:: the ancilla bit.
    * C_value:: the value of constant "C", should be smaller than the spectrum "gap".
"""
struct HHLCRot{N, NC, T} <: PrimitiveBlock{N}
    cbits::Vector{Int}
    ibit::Int
    C_value::T
    HHLCRot{N}(cbits::Vector{Int}, ibit::Int, C_value::T) where {N, T} = new{N, length(cbits), T}(cbits, ibit, C_value)
end

@inline function hhlrotmat(λ::Real, C_value::Real)
    b = C_value/λ
    a = sqrt(1-b^2)
    a, -b, b, a
end

function apply!(reg::ArrayReg, hr::HHLCRot{N, NC, T}) where {N, NC, T}
    mask = bmask(hr.ibit)
    step = 1<<(hr.ibit-1)
    step_2 = step*2
    nbit = nqubits(reg)
    for j = 0:step_2:size(reg.state, 1)-step
        for i = j+1:j+step
            λ = bfloat(readbit(i-1, hr.cbits...), nbits=nbit-1)
            if λ >= hr.C_value
                u = hhlrotmat(λ, hr.C_value)
                u1rows!(state(reg), i, i+step, u...)
            end
        end
    end
    reg
end

"""
    hhlproject!(all_bit::ArrayReg, n_reg::Int) -> Vector

project to aiming state |1>|00>|u>, and return |u> vector.
"""
function hhlproject!(all_bit::ArrayReg, n_reg::Int)
    all_bit |> focus!(1:(n_reg+1)...) |> select!(1) |> state |> vec
end

"""
Function to build up a HHL circuit.
"""
function hhlcircuit(UG, n_reg::Int, C_value::Real)
    n_b = nqubits(UG)
    n_all = 1 + n_reg + n_b
    pe = PEBlock(UG, n_reg, n_b)
    cr = HHLCRot{n_reg+1}([2:n_reg+1...], 1, C_value)
    chain(n_all, concentrate(n_all, pe, [2:n_all...,]), concentrate(n_all, cr, [1:(n_reg+1)...,]), concentrate(n_all, pe', [2:n_all...,]))
end

"""
    hhlsolve(A::Matrix, b::Vector) -> Vector

solving linear system using HHL algorithm. Here, A must be hermitian.
"""
function hhlsolve(A::Matrix, b::Vector, n_reg::Int, C_value::Real)
    if !ishermitian(A)
        throw(ArgumentError("Input matrix not hermitian!"))
    end
    UG = matblock(exp(2π*im.*A))

    # Generating input bits
    all_bit =  ArrayReg(b) ⊗ zero_state(n_reg) ⊗ zero_state(1)

    # Construct HHL circuit.
    circuit = hhlcircuit(UG, n_reg, C_value)

    # Apply bits to the circuit.
    apply!(all_bit, circuit)

    # Get state of aiming state |1>|00>|u>.
    hhlproject!(all_bit, n_reg) ./ C_value
end
