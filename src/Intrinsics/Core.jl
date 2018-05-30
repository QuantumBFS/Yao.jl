# permmatrix.jl & identity.jl
export PermMatrix, pmrand, Identity, II

# basic_gates.jl
export P0, P1, PAULI_X, PAULI_Y, PAULI_Z, CNOT_MAT, TOFFOLI_MAT, Pu, Pd, H_MAT



# basis.jl
export basis, bmask
export bsizeof, bit_length, log2i
export testall, testany, testval, setbit, setbit!, flip, flip!, neg, swapbits, swapbits!
export indices_with

# gates.jl
export general_controlled_gates, hilbertkron
export xgate, ygate, zgate
export czgate, cygate, czgate
export controlled_U1
