# # Register Basics
# ## Table of Contents
# * Construction and Storage
# * Basics Arithmatics
# * Fidelity and DensityMatrix
# * Batched Registers

using Yao
using LinearAlgebra

# ## Construction and Storage
# `AbstractRegister{B, T}` is abstract type that registers will subtype from. B is the batch size, T is the data type.
# Normally, we use a matrix as the `state` (with columns the batch and environment dimension) of a register, which is called `DefaultRegister{B, T}`.

# To initialize a quantum register, all you need is
# * `register(vec)`,
# * `zero_state(nbit)`,
# * `rand_state(nbit)`, both real and imaginary parts are random normal distributions,
# * `product_state(nbit, val=0)`, where val is an `Integer` as bitstring, e.g. `0b10011` or `19`,
# * `uniform_state(nbit)`, evenly distributed state, i.e. H|0>.

# e.g.

ψ1 = zero_state(5)
@show ψ1
@show nqubits(ψ1)
@show nactive(ψ1)   # number of activated qubits
@show nremain(ψ1)   # number of remaining qubits

ψ2 = ψ1 |> focus!(3,2,4)   # set activated qubits
@show ψ2
@show nqubits(ψ2)
@show nactive(ψ2)
@show nremain(ψ2)

@assert relax!(ψ2, (3,2,4)) == ψ1

# The total number of qubits here is 5, they are all acitve by default. `active` qubits are also called `system` qubits that are visible to operations, `remaining` qubits are the `environment`. `nremain == nqubits-nactive` always holds.
#
# **focus! & relax!**
# `focus!(reg, (3,2,4))` is equivalent to `reg |> focus!(3,2,4)`, which changes focused bits to `(3,2,4)`. Here from ψ1 -> ψ2, qubit line numbers change as
# `(active)(remaining): (1,2,3,4,5)() -> (3,2,4)(1,5)`
#
# `focus!` uses *relative positions*, which means it sees only active qubits and does not memorize original qubits positions. We take this convension to support **modulized design**. For example, if we want to insert a `QFT` blocks into some parent module, both the `QFT` and its parent do not need to know `original position`, which provides flexibility.
#
# `relax!` is the inverse process of `focus!`, `relax!(reg, (3,2,4))` will cancel the above operation. Here we have a second parameter since a register does not memorize original positions. This annoying feature can be circumvented using `focus!(reg, (3,2,4)) do ... end`, which will automatically restore your focus operation, see an example [here](@ref focusdo).
#
# Please also notice **APIs for changing lines order**
# * reorder!(reg, order), change lines order
# * reg |> invorder!, inverse lines order
#
# and
# * reg |> oneto(n), return a register `view`, with first `n` bits focused.

#---------------
# **Extending Registers**
# We can extend registers by either joining two registers or adding bits.

@assert product_state(3, 0b110) ⊗ product_state(3, 0b001) == product_state(6, 0b110001)

#--------------
reg = product_state(5, 0b11100)
@assert addbit!(copy(reg), 2) == product_state(7, 0b0011100) == zero_state(2) ⊗ reg

# **Storage**
# Let's dive into the storage of a register, there are three types `representation`s
# * `reg |> state`, matrix format, size = `(2^nactive, 2^nremain * nbatch)`
# * `reg |> rank3`, rank 3 tensor format, size = `(2^nactive, 2^nremain, nbatch)`
# * `reg |> hypercubic`, hypercubic format, size = `(2, 2, 2, ..., nbatch)`

# Here, we add a dimension `nbatch` to support parallism among registers.
# They are all different views of same memory. Please also check `statevec` and `relaxedvec` format, which prefer vectors whenever possible.

@show ψ1 |> state |> size
@show ψ1 |> rank3 |> size
@show ψ1 |> hypercubic |> size
@show ψ1 |> statevec |> size
@show ψ1 |> relaxedvec |> size;

# ### [Example](@id focusdo)
# multiply `|0>` by a random unitary operator on qubits `(3, 1, 5)` (relax the register afterwards).

using Yao.Intrinsics: rand_unitary

reg = zero_state(5)
focus!(reg, [3,1,5]) do r
    r.state = rand_unitary(8) * r.state
    r
end
@show reg.state;

# ## Basic Arithmatics
# `+, -, *, /, ⊗, '` are implemented.
#
# The adjoint of a register is also called `bra`, it can be used in calculating state overlap

ψ1 = rand_state(5)
ψ2 = rand_state(5)

# arithmatics
@show ψ1
@show ψ2
@show ψ3 = (0.3ψ1 + 2ψ2)/2 ⊗ ψ1
@assert ψ3 ≈ 0.15ψ1 ⊗ ψ1 + ψ2 ⊗ ψ1

# normalize ψ3
@assert ψ1 |> isnormalized && ψ2 |> isnormalized
@assert ψ3 |> isnormalized == false
@show ψ3 |> normalize! |> isnormalized

@show ψ3' * ψ3;

# ## Measure
# * `measure(reg)`, measure without collapsing state,
# * `measure!(reg)`, measure and collapse,
# * `measure_remove!(reg)`, measure focused bits and remove them,
# * `measure_reset!(reg, val=0)`, measure focused bits and reset them to some value,
# * `reset!(reg)`, collapse to specific value directly.
# * `select(reg, x)`, select subspace projected on specific basis, i.e. $|\phi\rangle = |x\rangle\langle x|\psi\rangle$.

#----------
# **measure**

@show product_state(5, 0b11001) |> measure  # please notice binary number `0b11001` is equivalent to `25`!
reg = rand_state(7)
@show measure(reg, 5);          # measure multiple times

# **measure!**
reg = rand_state(7)
@show [measure!(reg) for i=1:5];  # measure! will collapse state

# **measure_reset!**
reg = rand_state(7)
@show [measure_reset!(reg, val=i*10) for i=1:5];   # measure_reset! will reset the measured bit to target state (default is `0`)

# **measure_remove!**
reg = rand_state(7)
@show measure_remove!(reg)
@show reg;

reg = rand_state(7)
@show measure_remove!(reg |> focus!(2,3))
@show reg;

# **select**
#
# select will allow you to get the disired measurement result, and collapse to that state.
# It is equivalent to calculating $|\phi\rangle = |x\rangle\langle x|\psi\rangle$.
reg = rand_state(9) |> focus!(1, 2, 3, 4)
@show ψ = select(reg, 0b1110)
@show ψ |> relax!;

## Fidelity and Density Matrix
ψ1 = rand_state(6)
ψ2 = rand_state(6)
@show fidelity(ψ1, ψ2)
@show tracedist(ψ1, ψ2)
@show ψ1 |> ρ
@show tracedist(ψ1 |> ρ, ψ2|> ρ);  # calculate trace distance using density matrix
@assert ψ1 |> probs ≈ dropdims(ψ1 |> ρ |> probs, dims=2)

# ## Batched Registers
#
# Most operations support batched register, which means running multiple registers in parallel.
ψ = rand_state(6, 3)
@show ψ
@show nbatch(ψ)
@show viewbatch(ψ, 2)  # this is a view of register at 2nd column of the batch dimension
@show repeat(ψ, 3);    # repeat registers in batch dimension

# **broadcasting along batch dimension**
@. ψ * 5 - 4 * ψ ≈ ψ
#------------------
X2 = put(5, 2=>X)       # X operator on 2nd bit, with total number of bit 5.
direct = copy(ψ) |> X2  # applying X2 directly
map(reg->reg |> X2, ψ)  # applying X2 using broadcasting, here X2 operator is applied inplace!
ψ .≈ direct
