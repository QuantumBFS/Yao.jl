export qft_circuit

"""
    cphase(i, j)

Control phase gate.
"""
cphase(i, j) = control(i, j=> shift(2π/(2^(i-j+1))));


hcphases(n, i) = chain(n, i==j ? put(i=>H) : cphase(j, i) for j in i:n);

"""
    qft_circuit(n)

Create a Quantum Fourer Transform circuit. See also [`QFT`](@ref).
"""
qft_circuit(n::Int) = chain(n, hcphases(n, i) for i = 1:n)
