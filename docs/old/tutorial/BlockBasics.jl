# # Block Basics
# ## Table of Contents
# * Construction and Matrix Representation
# * Block Tree Architecture
# * Tagging System
# * Parameter System
# * Differentiable Blocks
# * Time Evolution and Hamiltonian

using Yao, Yao.Blocks
using LinearAlgebra

# ## Construction and Matrix Representation
# Blocks are operations on registers, we call those with matrix representation (linear) `MatrixBlock`.

# A `MatrixBlock` can be
# * isunitary, $O^\dagger O=I$
# * ishermitian, $O^\dagger = O$
# * isreflexive, $O^2 = 1$

@show X
@show X |> typeof
@show isunitary(X)
@show ishermitian(X)
@show isreflexive(X);

# **matrix representation**
mat(X)

# **composite gates**
# Embeding an X gate into larger Hilbert space, the first parameter of most non-primitive constructors are always qubit numbers

@show X2 = put(3, 2=>X)
@show isunitary(X2)
@show ishermitian(X2)
@show isreflexive(X2);

#---------------
mat(X2)
#---------------
@show cx = control(3, 3, 1=>X)
@show isunitary(cx)
@show ishermitian(cx)
@show isreflexive(cx);
#---------------
mat(cx)
# hermitian and reflexive blocks can be used to construct rotation gates
@show rx = rot(X, π/4)
@show isunitary(rx)
@show ishermitian(rx)
@show isreflexive(rx);

#-----------------
mat(rx)

# now let's build a random circuit for following demos
using Yao.Intrinsics: rand_unitary
circuit = chain(5, control(5, 3=>Rx(0.25π)), put(5, (2,3)=>matrixgate(rand_unitary(4))), swap(5, 3, 4), repeat(5, H, 2:5), put(5, 2=>Ry(0.6)))
# to apply it on some register, we can use
reg = zero_state(10)
focus!(reg, 1:5) do reg_focused
    apply!(reg_focused, circuit)
end
@show reg ≈ zero_state(10);   # reg is changed!
# then we reverse the process and check the correctness
focus!(reg, 1:5) do reg_focused
    reg_focused |> circuit'
end
@show reg ≈ zero_state(10);   # reg is restored!
# Here, we have used the pip "eye candy" `reg |> block` to represent applying a block on register, which is equivalent to `apply!(reg, block)`
#---------------

# **Type Tree**
# To see a full list of block types
using InteractiveUtils: subtypes
function subtypetree(t, level=1, indent=4)
   level == 1 && println(t)
   for s in subtypes(t)
     println(join(fill(" ", level * indent)) * string(s))
     subtypetree(s, level+1, indent)
   end
end

subtypetree(Yao.Blocks.AbstractBlock);

# In the top level, we have
# * `MatrixBlock`, linear operators
# * `AbstractMeasure`, measurement operations
# * `FunctionBlock`, a wrapper for register function that take register as input, change the register inplace and return the register.
# * `Sequential`, a container for **block tree**, which is similar to `ChainBlock`, but has less constraints.

# ## Block Tree Architecture
# A block tree is specified the following two APIs
# * subblocks(block), siblings of a block.
# * chsubblocks, change siblings of a node.
crx = circuit[1]
@show crx
@show subblocks(crx)
@show chsubblocks(crx, (Y,));

# if we want to define a function that travals over the tree in depth first order, we can write something like
function print_block_tree(root, depth=0)
    println("  "^depth * "- $(typeof(root).name)")
    print_block_tree.(root |> subblocks, depth+1)
end
print_block_tree(circuit);

# there are some functions defined using this strategy, like `collect(circuit, block_type)`, it can filter out any type of blocks
rg = collect(circuit, RotationGate)

# ## Tagging System
# We proudly introduced our tag system here.
# In previous sections, we have introduced the magic operation `circuit'` to get the dagger a circuit, its realization is closely related to the tagging mechanism of `Yao`.
@show X'    # hermitian gate
@show Pu'   # special gate
@show Rx(0.5)';   # rotation gate

# The dagger of above gates can be translated to other gates easily.
# but some blocks has no predefined dagger operations, then we put a tag for it as a default behavior, e.g.
daggered_gate = matrixgate(randn(4, 4))'
@show daggered_gate |> typeof
daggered_gate
# Here, `Daggered` is a subtype of `TagBlock`.
#--------------------
# Other tag blocks include
#-----------------
# **Scale**, static scaling
2X
# **CachedBlock**, get the matrix representation of a block when applying it on registers, and cache it in memory (or `CacheServer` more precisely).
# This matrix can be useful in future calculation, like boosting time evolution.
put(5, 2=>X) |> cache
# **AbstactDiff**, marks a block as differentiable, either in classical `back propagation` mode (with extra memory cost to store intermediate data)
put(5, 2=>Rx(0.3)) |> autodiff(:BP)
# or non-cheating quantum circuit simulation
put(5, 2=>Rx(0.3)) |> autodiff(:QC)

# ## Parameter System
# using the depth first searching strategy, we can find all parameters in a tree or subtree. Two relevant APIs are
# * parameters(block), get all parameters in a (sub)tree rooted on block
# * dispatch!([func], block, params), dispatch `params` into (sub)tree rooted on `block`, optional parameter `func` can be used to custom parameter update rule.
@show parameters(circuit)
dispatch!(circuit, [0.1, 0.9])
@show parameters(circuit)
dispatch!(+, circuit, [0.1, 0.1])
@show parameters(circuit)
dispatch!(circuit, :zero)
@show parameters(circuit)
dispatch!(circuit, :random)
@show parameters(circuit);

# ### Intrinsic parameters
# Intrinsic parameters are block's net contribution to total paramters, normally, we define these two APIs for subtyping blocks
# * `iparameters(block)`,
# * `setiparameters!(block, params...)`,
@show iparameters(Rx(0.3))
@show setiparameters!(Rx(0.3), 1.2)
@show chain(Rx(0.3), Ry(0.5)) |> iparameters;

# ## Differentiable Blocks
# see the independant chapter [Automatic Differentiation](@ref autodiff)
#-----------------
# ## Time Evolution and Hamiltonian
# docs are under preparation
