# # Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit

# First, you have to use this package in Julia.

using Yao, Yao.Blocks

# Then let's define the oracle, it is a function of the number of qubits.
# The circuit looks like this:

# ![ghz](../assets/figures/ghz4.png)

n = 4
circuit(n) = chain(
    n,
    put(1=>X),
    repeat(H, 2:n),
    control(2, 1=>X),
    control(4, 3=>X),
    control(3, 1=>X),
    control(4, 3=>X),
    repeat(H, 1:n),
)

# Let me explain what happens here. Firstly, we have an `X` gate which is applied to the first
# qubit. We need decide how we calculate this numerically, `Yao` offers serveral different approach
# to this. The simplest one is to use `put(n, ibit=>gate)` to apply a gate on the register.
# The first argument `n` means the number of qubits, it can be lazy evaluated.

put(n, 1=>X) == put(1=>X)(n)

# If you wanted to apply a two qubit gate,
put(n, (2,1)=>CNOT)

# However, this kind of general apply is not as efficient as the following statement
mat(put(n, (2,1)=>CNOT)) ≈ mat(control(n, 2, 1=>X))

# This means there is a `X` gate on the first qubit that is controled by the second qubit.
# `Yao.jl` providea a simple API `mat` to obtain the matrix representation of a block SUPER efficiently.
# This distinct feature helps users debug their quantum programs easily, and is equally useful in time evolution and ground state solving problems.

# For a multi-controlled gate like Toffoli gate, the construction is quite intuitive
control(n, (2, 1), 3=>X)
# Do you know how to construct a general multi-control, multi-qubit gate? Just have a guess and try it out!

# In the begin and end, we need to apply `H` gate to all lines, you can do it by `repeat`,
# For some specific types of gates such as `X`, `Y` and `Z`, applying multiple of them can be as efficient as applying single gate.

# The whole circuit is a chained structure of the above blocks. And we actually store a quantum
# circuit in a tree structure.

circuit

# After we have an circuit, we can construct a quantum register, and
# input it into the oracle. You will then receive this register after
# processing it.

r = apply!(register(bit"0000"), circuit(4))

# Let's check the output:

statevec(r)

# We have a GHZ state here, try to measure the first qubit

measure(r, nshot=1000)

# ![GHZ](../assets/figures/GHZ.png)

# GHZ state will collapse to ``|0000\rangle`` or ``|1111\rangle`` due to entanglement!
