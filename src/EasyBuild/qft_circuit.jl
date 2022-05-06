export qft_circuit

"""
    cphase(nbits, i, j, θ)

Control-phase gate.
"""
cphase(nbits::Int, i::Int, j::Int, θ::T) where T = control(nbits, i, j=>shift(θ))

"""
    qft_circuit([T=Float64], n)

The quantum Fourer transformation (QFT) circuit.
The first parameter `T` is the parameter type.

References
------------------------
* [Wiki](https://en.wikipedia.org/wiki/Quantum_Fourier_transform)
"""
qft_circuit(::Type{T}, n::Int) where T = chain(n, hcphases(T, n, i) for i = 1:n)
hcphases(::Type{T}, n, i) where T = chain(n, i==j ? put(i=>H) : cphase(n, j, i, 2T(π)/T(2^(j-i+1))) for j in i:n);
qft_circuit(n::Int) = qft_circuit(Float64, n)
