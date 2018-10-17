# # Binary Basics
# This tutorial is about operations about basis, it is mainly designed for developers, but is also useful to users.
using Yao, Yao.Intrinsics
#------------------
# ## Table of Contents
# * Storage of Computing Bases
# * Binray Operations
# * Number Readouts
# * Iterating over Bases
#---------------------
# ## Storage of Computing Bases
# We use an `Int` type to store spin configurations, e.g. `0b011101` (`29`) represents qubit configuration
# ```math
# \sigma_1=1, \sigma_2=0, \sigma_3=1, \sigma_4=1, \sigma_5=1, \sigma_6=0
# ```
# so we relate the configurations $\vec σ$ with integer $b$ by $b = \sum\limits_i 2^{i-1}σ_i$.
#----------------------------
# related APIs are
# * `integer(s) |> bitarray(nbit)`, transform integers to bistrings of type `BitArray`.
# * `bitstring |> packabits`, transform bitstrings to integers.
# * `integer |> baddrs`, get the locations of nonzero qubits.
@show 4 |> bitarray(5)
@show [4, 5, 6] |> bitarray(5)
@show [1, 1 , 0] |> packbits
@show [4, 5, 6] |> bitarray(5) |> packbits
@show baddrs(0b011);

# ## Binray Operations
takebit(0b11100, 2, 3)

# Masking is an important concept for binary operations, to generate a mask with specific position masked, e.g. we want to mask qubits `1, 3, 4`
mask = bmask(UInt8, 1,3,4)
@assert mask == 0b1101;

# with this mask, we can
@show testall(0b1011, mask) # true if all masked positions are 1
@show testany(0b1011, mask) # true if any masked positions is 1
@show testval(0b1011, mask, 0b1001)  # true if mask outed position matches `0b1001`
@show flip(0b1011, mask)  # flip masked positions
@show swapbits(0b1011, 0b1100)  # swap masked positions
@show setbit(0b1011, 0b1100);  # set masked positions 1

# For more interesting bitwise operations, see manual page [Yao.Intrinsics](@ref Intrinsics).
#----------------------------------
# ## Number Readouts
# In phase estimation and HHL algorithms, we sometimes need to readouts qubits as integer or float point numbers.
# We can read the register in different ways, like
# * bint, the integer itself
# * bint_r, the integer with bits small-big end reflected.
# * bfloat, the float point number 0.σ₁σ₂...σₙ.
# * bfloat_r, the float point number 0.σₙ...σ₂σ₁.
@show bint(0b010101)
@show bint_r(0b010101, nbit=6)
@show bfloat(0b010101)
@show bfloat_r(0b010101, nbit=6);

# Notice here functions with `_r` ending always require `nbit` as an additional input parameter to help reading, which is regarded as less natural way of expressing numbers.
#----------------------
# ## Iterating over Bases
# Counting from `0` is very natural way of iterating quantum registers, very pity for `Julia`
@show basis(4);

# `itercontrol` is a complicated API, but it plays an fundamental role in high performance quantum simulation of `Yao`.
# It is used for iterating over basis in controlled way, its interface looks like
@doc itercontrol
# Here, `poss` is a vector of controled positions, `vals` is a vector of values in controled positions.
#-------------
# ### example
# In a 4 qubit system, find out basis with 1st and 3rd qubits in state `0` and `1` respectively.
ic = itercontrol(4, [1,3], [0,1])
for i in ic
    println(i |> bitarray(4) .|> Int)
end
# Here, we have 1st and 3rd bits controlled,
# only 2 qubits are free, so the size of phase space here is `4`.
