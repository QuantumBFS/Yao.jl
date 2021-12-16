export qft_circuit

"""
    cphase(nbits, i, j, θ)

Control-phase gate.
"""
cphase(nbits::Int, i::Int, j::Int, θ::T) where T = control(nbits, i, j=>shift(θ))

"""
    qft_circuit(n)

The quantum Fourer transformation (QFT) circuit.

References
------------------------
* [Wiki](https://en.wikipedia.org/wiki/Quantum_Fourier_transform)
"""
qft_circuit(n::Int) = chain(n, hcphases(n, i) for i = 1:n)
hcphases(n, i) = chain(n, i==j ? put(i=>H) : cphase(n, j, i, 2π/(2^(j-i+1))) for j in i:n);