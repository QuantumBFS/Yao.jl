var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": "CurrentModule = Yao"
},

{
    "location": "#Yao-1",
    "page": "Home",
    "title": "Yao",
    "category": "section",
    "text": "A General Purpose Quantum Computation Simulation FrameworkWelcome to Yao, a Flexible, Extensible, Efficient Framework for Quantum Algorithm Design. Yao (幺) is the Chinese character for unitary. It is also means the first (一) in Chinese (it is the first released package from QuantumBFS).We aim to provide a powerful tool for researchers, students to study and explore quantum computing in near term future, before quantum computer being used in large-scale."
},

{
    "location": "#Tutorial-1",
    "page": "Home",
    "title": "Tutorial",
    "category": "section",
    "text": "Pages = [\n    \"tutorial/RegisterBasics.md\",\n    \"tutorial/BlockBasics.md\",\n    \"tutorial/Diff.md\",\n    \"tutorial/BinaryBasics.md\",\n]\nDepth = 1"
},

{
    "location": "#Examples-1",
    "page": "Home",
    "title": "Examples",
    "category": "section",
    "text": "Pages = [\n    \"tutorial/GHZ.md\",\n    \"tutorial/QFT.md\",\n    \"tutorial/Grover.md\",\n    \"tutorial/QCBM.md\",\n]\nDepth = 1"
},

{
    "location": "#Manual-1",
    "page": "Home",
    "title": "Manual",
    "category": "section",
    "text": "Pages = [\n    \"man/interfaces.md\",\n    \"man/registers.md\",\n    \"man/blocks.md\",\n    \"man/intrinsics.md\",\n]\nDepth = 1"
},

{
    "location": "tutorial/RegisterBasics/#",
    "page": "Register Basics",
    "title": "Register Basics",
    "category": "page",
    "text": "EditURL = \"https://github.com/QuantumBFS/Yao.jl/blob/master/../../../../build/QuantumBFS/Yao.jl/docs/src/tutorial/RegisterBasics.jl\""
},

{
    "location": "tutorial/RegisterBasics/#Register-Basics-1",
    "page": "Register Basics",
    "title": "Register Basics",
    "category": "section",
    "text": ""
},

{
    "location": "tutorial/RegisterBasics/#Table-of-Contents-1",
    "page": "Register Basics",
    "title": "Table of Contents",
    "category": "section",
    "text": "Construction and Storage\nBasics Arithmatics\nFidelity and DensityMatrix\nBatched Registersusing Yao\nusing LinearAlgebra"
},

{
    "location": "tutorial/RegisterBasics/#Construction-and-Storage-1",
    "page": "Register Basics",
    "title": "Construction and Storage",
    "category": "section",
    "text": "AbstractRegister{B, T} is abstract type that registers will subtype from. B is the batch size, T is the data type. Normally, we use a matrix as the state (with columns the batch and environment dimension) of a register, which is called DefaultRegister{B, T}.To initialize a quantum register, all you need isregister(vec),\nzero_state(nbit),\nrand_state(nbit), both real and imaginary parts are random normal distributions,\nproduct_state(nbit, val=0), where val is an Integer as bitstring, e.g. 0b10011 or 19,\nuniform_state(nbit), evenly distributed state, i.e. H|0>.e.g.ψ1 = zero_state(5)\n@show ψ1\n@show nqubits(ψ1)\n@show nactive(ψ1)   # number of activated qubits\n@show nremain(ψ1)   # number of remaining qubits\n\nψ2 = ψ1 |> focus!(3,2,4)   # set activated qubits\n@show ψ2\n@show nqubits(ψ2)\n@show nactive(ψ2)\n@show nremain(ψ2)\n\n@assert relax!(ψ2, (3,2,4)) == ψ1The total number of qubits here is 5, they are all acitve by default. active qubits are also called system qubits that are visible to operations, remaining qubits are the environment. nremain == nqubits-nactive always holds.focus! & relax! focus!(reg, (3,2,4)) is equivalent to reg |> focus!(3,2,4), which changes focused bits to (3,2,4). Here from ψ1 -> ψ2, qubit line numbers change as (active)(remaining): (1,2,3,4,5)() -> (3,2,4)(1,5)focus! uses relative positions, which means it sees only active qubits and does not memorize original qubits positions. We take this convension to support modulized design. For example, if we want to insert a QFT blocks into some parent module, both the QFT and its parent do not need to know original position, which provides flexibility.relax! is the inverse process of focus!, relax!(reg, (3,2,4)) will cancel the above operation. Here we have a second parameter since a register does not memorize original positions. This annoying feature can be circumvented using focus!(reg, (3,2,4)) do ... end, which will automatically restore your focus operation, see an example here.Please also notice APIs for changing lines orderreorder!(reg, order), change lines order\nreg |> invorder!, inverse lines orderandreg |> oneto(n), return a register view, with first n bits focused.Extending Registers We can extend registers by either joining two registers or adding bits.@assert product_state(3, 0b110) ⊗ product_state(3, 0b001) == product_state(6, 0b110001)reg = product_state(5, 0b11100)\n@assert addbit!(copy(reg), 2) == product_state(7, 0b0011100) == zero_state(2) ⊗ regStorage Let\'s dive into the storage of a register, there are three types representationsreg |> state, matrix format, size = (2^nactive, 2^nremain * nbatch)\nreg |> rank3, rank 3 tensor format, size = (2^nactive, 2^nremain, nbatch)\nreg |> hypercubic, hypercubic format, size = (2, 2, 2, ..., nbatch)Here, we add a dimension nbatch to support parallism among registers. They are all different views of same memory. Please also check statevec and relaxedvec format, which prefer vectors whenever possible.@show ψ1 |> state |> size\n@show ψ1 |> rank3 |> size\n@show ψ1 |> hypercubic |> size\n@show ψ1 |> statevec |> size\n@show ψ1 |> relaxedvec |> size;"
},

{
    "location": "tutorial/RegisterBasics/#focusdo-1",
    "page": "Register Basics",
    "title": "Example",
    "category": "section",
    "text": "multiply |0> by a random unitary operator on qubits (3, 1, 5) (relax the register afterwards).using Yao.Intrinsics: rand_unitary\n\nreg = zero_state(5)\nfocus!(reg, [3,1,5]) do r\n    r.state = rand_unitary(8) * r.state\n    r\nend\n@show reg.state;"
},

{
    "location": "tutorial/RegisterBasics/#Basic-Arithmatics-1",
    "page": "Register Basics",
    "title": "Basic Arithmatics",
    "category": "section",
    "text": "+, -, *, /, ⊗, \' are implemented.The adjoint of a register is also called bra, it can be used in calculating state overlapψ1 = rand_state(5)\nψ2 = rand_state(5)arithmatics@show ψ1\n@show ψ2\n@show ψ3 = (0.3ψ1 + 2ψ2)/2 ⊗ ψ1\n@assert ψ3 ≈ 0.15ψ1 ⊗ ψ1 + ψ2 ⊗ ψ1normalize ψ3@assert ψ1 |> isnormalized && ψ2 |> isnormalized\n@assert ψ3 |> isnormalized == false\n@show ψ3 |> normalize! |> isnormalized\n\n@show ψ3\' * ψ3;"
},

{
    "location": "tutorial/RegisterBasics/#Measure-1",
    "page": "Register Basics",
    "title": "Measure",
    "category": "section",
    "text": "measure(reg; nshot=1), measure without collapsing state,\nmeasure!(reg), measure and collapse,\nmeasure_remove!(reg), measure focused bits and remove them,\nmeasure_reset!(reg, val=0), measure focused bits and reset them to some value,\nreset!(reg), collapse to specific value directly.\nselect(reg, x), select subspace projected on specific basis, i.e. phirangle = xranglelangle xpsirangle.measure@show product_state(5, 0b11001) |> measure  # please notice binary number `0b11001` is equivalent to `25`!\nreg = rand_state(7)\n@show measure(reg; nshot=5);          # measure multiple timesmeasure!reg = rand_state(7)\n@show [measure!(reg) for i=1:5];  # measure! will collapse statemeasure_reset!reg = rand_state(7)\n@show [measure_reset!(reg, val=i*10) for i=1:5];   # measure_reset! will reset the measured bit to target state (default is `0`)measure_remove!reg = rand_state(7)\n@show measure_remove!(reg)\n@show reg;\n\nreg = rand_state(7)\n@show measure_remove!(reg |> focus!(2,3))\n@show reg;selectselect will allow you to get the disired measurement result, and collapse to that state. It is equivalent to calculating phirangle = xranglelangle xpsirangle.reg = rand_state(9) |> focus!(1, 2, 3, 4)\n@show ψ = select(reg, 0b1110)\n@show ψ |> relax!;\n\n# Fidelity and Density Matrix\nψ1 = rand_state(6)\nψ2 = rand_state(6)\n@show fidelity(ψ1, ψ2)\n@show tracedist(ψ1, ψ2)\n@show ψ1 |> ρ\n@show tracedist(ψ1 |> ρ, ψ2|> ρ);  # calculate trace distance using density matrix\n@assert ψ1 |> probs ≈ dropdims(ψ1 |> ρ |> probs, dims=2)"
},

{
    "location": "tutorial/RegisterBasics/#Batched-Registers-1",
    "page": "Register Basics",
    "title": "Batched Registers",
    "category": "section",
    "text": "Most operations support batched register, which means running multiple registers in parallel.ψ = rand_state(6, 3)\n@show ψ\n@show nbatch(ψ)\n@show viewbatch(ψ, 2)  # this is a view of register at 2nd column of the batch dimension\n@show repeat(ψ, 3);    # repeat registers in batch dimensionbroadcasting along batch dimension@. ψ * 5 - 4 * ψ ≈ ψX2 = put(5, 2=>X)       # X operator on 2nd bit, with total number of bit 5.\ndirect = copy(ψ) |> X2  # applying X2 directly\nmap(reg->reg |> X2, ψ)  # applying X2 using broadcasting, here X2 operator is applied inplace!\nψ .≈ directThis page was generated using Literate.jl."
},

{
    "location": "tutorial/BlockBasics/#",
    "page": "Block Basics",
    "title": "Block Basics",
    "category": "page",
    "text": "EditURL = \"https://github.com/QuantumBFS/Yao.jl/blob/master/../../../../build/QuantumBFS/Yao.jl/docs/src/tutorial/BlockBasics.jl\""
},

{
    "location": "tutorial/BlockBasics/#Block-Basics-1",
    "page": "Block Basics",
    "title": "Block Basics",
    "category": "section",
    "text": ""
},

{
    "location": "tutorial/BlockBasics/#Table-of-Contents-1",
    "page": "Block Basics",
    "title": "Table of Contents",
    "category": "section",
    "text": "Construction and Matrix Representation\nBlock Tree Architecture\nTagging System\nParameter System\nDifferentiable Blocks\nTime Evolution and Hamiltonianusing Yao, Yao.Blocks\nusing LinearAlgebra"
},

{
    "location": "tutorial/BlockBasics/#Construction-and-Matrix-Representation-1",
    "page": "Block Basics",
    "title": "Construction and Matrix Representation",
    "category": "section",
    "text": "Blocks are operations on registers, we call those with matrix representation (linear) MatrixBlock.A MatrixBlock can beisunitary, O^dagger O=I\nishermitian, O^dagger = O\nisreflexive, O^2 = 1@show X\n@show X |> typeof\n@show isunitary(X)\n@show ishermitian(X)\n@show isreflexive(X);matrix representationmat(X)composite gates Embeding an X gate into larger Hilbert space, the first parameter of most non-primitive constructors are always qubit numbers@show X2 = put(3, 2=>X)\n@show isunitary(X2)\n@show ishermitian(X2)\n@show isreflexive(X2);mat(X2)@show cx = control(3, 3, 1=>X)\n@show isunitary(cx)\n@show ishermitian(cx)\n@show isreflexive(cx);mat(cx)hermitian and reflexive blocks can be used to construct rotation gates@show rx = rot(X, π/4)\n@show isunitary(rx)\n@show ishermitian(rx)\n@show isreflexive(rx);mat(rx)now let\'s build a random circuit for following demosusing Yao.Intrinsics: rand_unitary\ncircuit = chain(5, control(5, 3=>Rx(0.25π)), put(5, (2,3)=>matrixgate(rand_unitary(4))), swap(5, 3, 4), repeat(5, H, 2:5), put(5, 2=>Ry(0.6)))to apply it on some register, we can usereg = zero_state(10)\nfocus!(reg, 1:5) do reg_focused\n    apply!(reg_focused, circuit)\nend\n@show reg ≈ zero_state(10);   # reg is changed!then we reverse the process and check the correctnessfocus!(reg, 1:5) do reg_focused\n    reg_focused |> circuit\'\nend\n@show reg ≈ zero_state(10);   # reg is restored!Here, we have used the pip \"eye candy\" reg |> block to represent applying a block on register, which is equivalent to apply!(reg, block)Type Tree To see a full list of block typesusing InteractiveUtils: subtypes\nfunction subtypetree(t, level=1, indent=4)\n   level == 1 && println(t)\n   for s in subtypes(t)\n     println(join(fill(\" \", level * indent)) * string(s))\n     subtypetree(s, level+1, indent)\n   end\nend\n\nsubtypetree(Yao.Blocks.AbstractBlock);In the top level, we haveMatrixBlock, linear operators\nAbstractMeasure, measurement operations\nFunctionBlock, a wrapper for register function that take register as input, change the register inplace and return the register.\nSequential, a container for block tree, which is similar to ChainBlock, but has less constraints."
},

{
    "location": "tutorial/BlockBasics/#Block-Tree-Architecture-1",
    "page": "Block Basics",
    "title": "Block Tree Architecture",
    "category": "section",
    "text": "A block tree is specified the following two APIssubblocks(block), siblings of a block.\nchsubblocks, change siblings of a node.crx = circuit[1]\n@show crx\n@show subblocks(crx)\n@show chsubblocks(crx, (Y,));if we want to define a function that travals over the tree in depth first order, we can write something likefunction print_block_tree(root, depth=0)\n    println(\"  \"^depth * \"- $(typeof(root).name)\")\n    print_block_tree.(root |> subblocks, depth+1)\nend\nprint_block_tree(circuit);there are some functions defined using this strategy, like collect(circuit, block_type), it can filter out any type of blocksrg = collect(circuit, RotationGate)"
},

{
    "location": "tutorial/BlockBasics/#Tagging-System-1",
    "page": "Block Basics",
    "title": "Tagging System",
    "category": "section",
    "text": "We proudly introduced our tag system here. In previous sections, we have introduced the magic operation circuit\' to get the dagger a circuit, its realization is closely related to the tagging mechanism of Yao.@show X\'    # hermitian gate\n@show Pu\'   # special gate\n@show Rx(0.5)\';   # rotation gateThe dagger of above gates can be translated to other gates easily. but some blocks has no predefined dagger operations, then we put a tag for it as a default behavior, e.g.daggered_gate = matrixgate(randn(4, 4))\'\n@show daggered_gate |> typeof\ndaggered_gateHere, Daggered is a subtype of TagBlock.Other tag blocks includeScale, static scaling2XCachedBlock, get the matrix representation of a block when applying it on registers, and cache it in memory (or CacheServer more precisely). This matrix can be useful in future calculation, like boosting time evolution.put(5, 2=>X) |> cacheAbstactDiff, marks a block as differentiable, either in classical back propagation mode (with extra memory cost to store intermediate data)put(5, 2=>Rx(0.3)) |> autodiff(:BP)or non-cheating quantum circuit simulationput(5, 2=>Rx(0.3)) |> autodiff(:QC)"
},

{
    "location": "tutorial/BlockBasics/#Parameter-System-1",
    "page": "Block Basics",
    "title": "Parameter System",
    "category": "section",
    "text": "using the depth first searching strategy, we can find all parameters in a tree or subtree. Two relevant APIs areparameters(block), get all parameters in a (sub)tree rooted on block\ndispatch!([func], block, params), dispatch params into (sub)tree rooted on block, optional parameter func can be used to custom parameter update rule.@show parameters(circuit)\ndispatch!(circuit, [0.1, 0.9])\n@show parameters(circuit)\ndispatch!(+, circuit, [0.1, 0.1])\n@show parameters(circuit)\ndispatch!(circuit, :zero)\n@show parameters(circuit)\ndispatch!(circuit, :random)\n@show parameters(circuit);"
},

{
    "location": "tutorial/BlockBasics/#Intrinsic-parameters-1",
    "page": "Block Basics",
    "title": "Intrinsic parameters",
    "category": "section",
    "text": "Intrinsic parameters are block\'s net contribution to total paramters, normally, we define these two APIs for subtyping blocksiparameters(block),\nsetiparameters!(block, params...),@show iparameters(Rx(0.3))\n@show setiparameters!(Rx(0.3), 1.2)\n@show chain(Rx(0.3), Ry(0.5)) |> iparameters;"
},

{
    "location": "tutorial/BlockBasics/#Differentiable-Blocks-1",
    "page": "Block Basics",
    "title": "Differentiable Blocks",
    "category": "section",
    "text": "see the independant chapter Automatic Differentiation"
},

{
    "location": "tutorial/BlockBasics/#Time-Evolution-and-Hamiltonian-1",
    "page": "Block Basics",
    "title": "Time Evolution and Hamiltonian",
    "category": "section",
    "text": "docs are under preparationThis page was generated using Literate.jl."
},

{
    "location": "tutorial/Diff/#",
    "page": "Automatic Differentiation",
    "title": "Automatic Differentiation",
    "category": "page",
    "text": ""
},

{
    "location": "tutorial/Diff/#autodiff-1",
    "page": "Automatic Differentiation",
    "title": "Automatic Differentiation",
    "category": "section",
    "text": ""
},

{
    "location": "tutorial/Diff/#Classical-back-propagation-1",
    "page": "Automatic Differentiation",
    "title": "Classical back propagation",
    "category": "section",
    "text": "Back propagation has O(M) complexity in obtaining gradients, with M the number of circuit parameters. We can use autodiff(:BP) to mark differentiable units in a circuit. Let\'s see an example."
},

{
    "location": "tutorial/Diff/#Example:-Classical-back-propagation-1",
    "page": "Automatic Differentiation",
    "title": "Example: Classical back propagation",
    "category": "section",
    "text": "using Yao\ncircuit = chain(4, repeat(4, H, 1:4), put(4, 3=>Rz(0.5)), control(2, 1=>X), put(4, 4=>Ry(0.2)))\ncircuit = circuit |> autodiff(:BP)From the output, we can see parameters of blocks marked by [∂] will be differentiated automatically.op = put(4, 3=>Y);  # loss is defined as its expectation.\nψ = rand_state(4);\nψ |> circuit;\nδ = ψ |> op;     # ∂f/∂ψ*\nbackward!(δ, circuit);    # classical back propagation!Here, the loss is L = <ψ|op|ψ>, δ = ∂f/∂ψ* is the error to be back propagated. The gradient is related to δ as fracpartial fpartialtheta = 2Refracpartial fpartialpsi^*fracpartial psi^*partialthetaIn face, backward!(δ, circuit) on wave function is equivalent to calculating δ |> circuit\' (apply!(reg, Daggered{<:BPDiff})). This function is overloaded so that gradientis for parameters are also calculated and stored in BPDiff block at the same time.Finally, we use gradient to collect gradients in the ciruits.g1 = gradient(circuit)  # collect gradientnote: Note\nIn real quantum devices, gradients can not be back propagated, this is why we need the following section."
},

{
    "location": "tutorial/Diff/#Quantum-circuit-differentiation-1",
    "page": "Automatic Differentiation",
    "title": "Quantum circuit differentiation",
    "category": "section",
    "text": "Experimental applicable differentiation strategies are based on the following two papersQuantum Circuit Learning, Kosuke Mitarai, Makoto Negoro, Masahiro Kitagawa, Keisuke Fujii\nDifferentiable Learning of Quantum Circuit Born Machine, Jin-Guo Liu, Lei WangThe former differentiation scheme is for observables, and the latter is for statistic functionals (U statistics). One may find the derivation of both schemes in this post.Realizable quantum circuit gradient finding algorithms have complexity O(M^2)."
},

{
    "location": "tutorial/Diff/#Example:-Practical-quantum-differenciation-1",
    "page": "Automatic Differentiation",
    "title": "Example: Practical quantum differenciation",
    "category": "section",
    "text": "We use QDiff block to mark differentiable circuitsusing Yao, Yao.Blocks\nc = chain(put(4, 1=>Rx(0.5)), control(4, 1, 2=>Ry(0.5)), kron(4, 2=>Rz(0.3), 3=>Rx(0.7))) |> autodiff(:QC)  # automatically mark differentiable blocksBlocks marked by [̂∂] will be differentiated.dbs = collect(c, QDiff)  # collect all QDiff blocksHere, we recommend collect QDiff blocks into a sequence using collect API for future calculations. Then, we can get the gradient one by one, using opdiffed = opdiff(dbs[1], put(4, 1=>Z)) do   # the exact differentiation with respect to first QDiff block.\n    zero_state(4) |> c\nendHere, contents in the do-block returns the loss, it must be the expectation value of an observable.For results checking, we get the numeric gradient use numdiffed = numdiff(dbs[1]) do    # compare with numerical differentiation\n   expect(put(4, 1=>Z), zero_state(4) |> c) |> real\nendThis numerical differentiation scheme is always applicable (even the loss is not an observable), but with numeric errors introduced by finite step size.We can also get all gradients using broadcastinged = opdiff.(()->zero_state(4) |> c, dbs, Ref(kron(4, 1=>Z, 2=>X)))   # using broadcast to get all gradients.note: Note\nSince BP is not implemented for QDiff blocks, the memory consumption is much less since we don\'t cache intermediate results anymore."
},

{
    "location": "tutorial/BinaryBasics/#",
    "page": "Binary Basics",
    "title": "Binary Basics",
    "category": "page",
    "text": "EditURL = \"https://github.com/QuantumBFS/Yao.jl/blob/master/../../../../build/QuantumBFS/Yao.jl/docs/src/tutorial/BinaryBasics.jl\""
},

{
    "location": "tutorial/BinaryBasics/#Binary-Basics-1",
    "page": "Binary Basics",
    "title": "Binary Basics",
    "category": "section",
    "text": "This tutorial is about operations about basis, it is mainly designed for developers, but is also useful to users.using Yao, Yao.Intrinsics"
},

{
    "location": "tutorial/BinaryBasics/#Table-of-Contents-1",
    "page": "Binary Basics",
    "title": "Table of Contents",
    "category": "section",
    "text": "Storage of Computing Bases\nBinray Operations\nNumber Readouts\nIterating over Bases"
},

{
    "location": "tutorial/BinaryBasics/#Storage-of-Computing-Bases-1",
    "page": "Binary Basics",
    "title": "Storage of Computing Bases",
    "category": "section",
    "text": "We use an Int type to store spin configurations, e.g. 0b011101 (29) represents qubit configurationsigma_1=1 sigma_2=0 sigma_3=1 sigma_4=1 sigma_5=1 sigma_6=0so we relate the configurations vec σ with integer b by b = sumlimits_i 2^i-1σ_i.related APIs areinteger(s) |> bitarray(nbit), transform integers to bistrings of type BitArray.\nbitstring |> packabits, transform bitstrings to integers.\ninteger |> baddrs, get the locations of nonzero qubits.@show 4 |> bitarray(5)\n@show [4, 5, 6] |> bitarray(5)\n@show [1, 1 , 0] |> packbits\n@show [4, 5, 6] |> bitarray(5) |> packbits\n@show baddrs(0b011);"
},

{
    "location": "tutorial/BinaryBasics/#Binray-Operations-1",
    "page": "Binary Basics",
    "title": "Binray Operations",
    "category": "section",
    "text": "takebit(0b11100, 2, 3)Masking is an important concept for binary operations, to generate a mask with specific position masked, e.g. we want to mask qubits 1, 3, 4mask = bmask(UInt8, 1,3,4)\n@assert mask == 0b1101;with this mask, we can@show testall(0b1011, mask) # true if all masked positions are 1\n@show testany(0b1011, mask) # true if any masked positions is 1\n@show testval(0b1011, mask, 0b1001)  # true if mask outed position matches `0b1001`\n@show flip(0b1011, mask)  # flip masked positions\n@show swapbits(0b1011, 0b1100)  # swap masked positions\n@show setbit(0b1011, 0b1100);  # set masked positions 1For more interesting bitwise operations, see manual page Yao.Intrinsics."
},

{
    "location": "tutorial/BinaryBasics/#Number-Readouts-1",
    "page": "Binary Basics",
    "title": "Number Readouts",
    "category": "section",
    "text": "In phase estimation and HHL algorithms, we sometimes need to readouts qubits as integer or float point numbers. We can read the register in different ways, likebint, the integer itself\nbint_r, the integer with bits small-big end reflected.\nbfloat, the float point number 0.σ₁σ₂...σₙ.\nbfloat_r, the float point number 0.σₙ...σ₂σ₁.@show bint(0b010101)\n@show bint_r(0b010101, nbit=6)\n@show bfloat(0b010101)\n@show bfloat_r(0b010101, nbit=6);Notice here functions with _r ending always require nbit as an additional input parameter to help reading, which is regarded as less natural way of expressing numbers."
},

{
    "location": "tutorial/BinaryBasics/#Iterating-over-Bases-1",
    "page": "Binary Basics",
    "title": "Iterating over Bases",
    "category": "section",
    "text": "Counting from 0 is very natural way of iterating quantum registers, very pity for Julia@show basis(4);itercontrol is a complicated API, but it plays an fundamental role in high performance quantum simulation of Yao. It is used for iterating over basis in controlled way, its interface looks like@doc itercontrolHere, poss is a vector of controled positions, vals is a vector of values in controled positions."
},

{
    "location": "tutorial/BinaryBasics/#example-1",
    "page": "Binary Basics",
    "title": "example",
    "category": "section",
    "text": "In a 4 qubit system, find out basis with 1st and 3rd qubits in state 0 and 1 respectively.ic = itercontrol(4, [1,3], [0,1])\nfor i in ic\n    println(i |> bitarray(4) .|> Int)\nendHere, we have 1st and 3rd bits controlled, only 2 qubits are free, so the size of phase space here is 4.This page was generated using Literate.jl."
},

{
    "location": "tutorial/GHZ/#",
    "page": "Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit",
    "title": "Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit",
    "category": "page",
    "text": "EditURL = \"https://github.com/QuantumBFS/Yao.jl/blob/master/../../../../build/QuantumBFS/Yao.jl/docs/src/tutorial/GHZ.jl\""
},

{
    "location": "tutorial/GHZ/#Prepare-Greenberger–Horne–Zeilinger-state-with-Quantum-Circuit-1",
    "page": "Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit",
    "title": "Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit",
    "category": "section",
    "text": "First, you have to use this package in Julia.using Yao, Yao.BlocksThen let\'s define the oracle, it is a function of the number of qubits. The circuit looks like this:(Image: ghz)n = 4\ncircuit(n) = chain(\n    n,\n    put(1=>X),\n    repeat(H, 2:n),\n    control(2, 1=>X),\n    control(4, 3=>X),\n    control(3, 1=>X),\n    control(4, 3=>X),\n    repeat(H, 1:n),\n)Let me explain what happens here. Firstly, we have an X gate which is applied to the first qubit. We need decide how we calculate this numerically, Yao offers serveral different approach to this. The simplest one is to use put(n, ibit=>gate) to apply a gate on the register. The first argument n means the number of qubits, it can be lazy evaluated.put(n, 1=>X) == put(1=>X)(n)If you wanted to apply a two qubit gate,put(n, (2,1)=>CNOT)However, this kind of general apply is not as efficient as the following statementmat(put(n, (2,1)=>CNOT)) ≈ mat(control(n, 2, 1=>X))This means there is a X gate on the first qubit that is controled by the second qubit. Yao.jl providea a simple API mat to obtain the matrix representation of a block SUPER efficiently. This distinct feature helps users debug their quantum programs easily, and is equally useful in time evolution and ground state solving problems.For a multi-controlled gate like Toffoli gate, the construction is quite intuitivecontrol(n, (2, 1), 3=>X)Do you know how to construct a general multi-control, multi-qubit gate? Just have a guess and try it out!In the begin and end, we need to apply H gate to all lines, you can do it by repeat, For some specific types of gates such as X, Y and Z, applying multiple of them can be as efficient as applying single gate.The whole circuit is a chained structure of the above blocks. And we actually store a quantum circuit in a tree structure.circuitAfter we have an circuit, we can construct a quantum register, and input it into the oracle. You will then receive this register after processing it.r = apply!(register(bit\"0000\"), circuit(4))Let\'s check the output:statevec(r)We have a GHZ state here, try to measure the first qubitmeasure(r, nshot=1000)(Image: GHZ)GHZ state will collapse to 0000rangle or 1111rangle due to entanglement!This page was generated using Literate.jl."
},

{
    "location": "tutorial/QFT/#",
    "page": "Quantum Fourier Transformation and Phase Estimation",
    "title": "Quantum Fourier Transformation and Phase Estimation",
    "category": "page",
    "text": ""
},

{
    "location": "tutorial/QFT/#Quantum-Fourier-Transformation-and-Phase-Estimation-1",
    "page": "Quantum Fourier Transformation and Phase Estimation",
    "title": "Quantum Fourier Transformation and Phase Estimation",
    "category": "section",
    "text": ""
},

{
    "location": "tutorial/QFT/#Quantum-Fourier-Transformation-1",
    "page": "Quantum Fourier Transformation and Phase Estimation",
    "title": "Quantum Fourier Transformation",
    "category": "section",
    "text": "(Image: ghz)using Yao\n\n# Control-R(k) gate in block-A\nA(i::Int, j::Int, k::Int) = control([i, ], j=>shift(2π/(1<<k)))\n# block-B\nB(n::Int, i::Int) = chain(i==j ? put(i=>H) : A(j, i, j-i+1) for j = i:n)\nQFT(n::Int) = chain(n, B(n, i) for i = 1:n)\n\n# define QFT and IQFT block.\nnum_bit = 5\nqft = QFT(num_bit)\niqft = qft\'   # get the hermitian conjugateThe basic building block - controled phase shift gate is defined asR(k)=beginbmatrix\n1  0\n0  expleft(frac2pi i2^kright)\nendbmatrixIn Yao, factory methods for blocks will be loaded lazily. For example, if you missed the total number of qubits of chain, then it will return a function that requires an input of an integer. So the following two statements are equivalentcontrol([4, ], 1=>shift(-2π/(1<<4)))(5) == control(5, [4, ], 1=>shift(-2π/(1<<4)))Both of then will return a ControlBlock instance. If you missed the total number of qubits. It is OK. Just go on, it will be filled when its possible.Once you have construct a block, you can inspect its matrix using mat function. Let\'s construct the circuit in dashed box A, and see the matrix of R_4 gatejulia> a = A(4, 1, 4)(5)\nTotal: 5, DataType: Complex{Float64}\ncontrol(4)\n└─ 1=>Phase Shift Gate:-0.39269908169872414\n\n\njulia> mat(a.block)\n2×2 Diagonal{Complex{Float64}}:\n 1.0+0.0im          ⋅         \n     ⋅      0.92388-0.382683imSimilarly, you can use put and chain to construct PutBlock (basic placement of a single gate) and ChainBlock (sequential application of MatrixBlocks) instances. Yao.jl view every component in a circuit as an AbstractBlock, these blocks can be integrated to perform higher level functionality.You can check the result using classical fft# if you\'re using lastest julia, you need to add the fft package.\nusing FFTW: fft, ifft\nusing LinearAlgebra: I\nusing Test\n\n@test chain(num_bit, qft, iqft) |> mat ≈ I\n\n# define a register and get its vector representation\nreg = rand_state(num_bit)\nrv = reg |> statevec |> copy\n\n# test fft\nreg_qft = apply!(copy(reg) |>invorder!, qft)\nkv = ifft(rv)*sqrt(length(rv))\n@test reg_qft |> statevec ≈ kv\n\n# test ifft\nreg_iqft = apply!(copy(reg), iqft)\nkv = fft(rv)/sqrt(length(rv))\n@test reg_iqft |> statevec ≈ kv |> invorderQFT and IQFT are different from FFT and IFFT in three ways,they are different by a factor of sqrt2^n with n the number of qubits.\nthe little end and big end will exchange after applying QFT or IQFT.\ndue to the convention, QFT is more related to IFFT rather than FFT."
},

{
    "location": "tutorial/QFT/#Phase-Estimation-1",
    "page": "Quantum Fourier Transformation and Phase Estimation",
    "title": "Phase Estimation",
    "category": "section",
    "text": "Since we have QFT and IQFT blocks we can then use them to realize phase estimation circuit, what we want to realize is the following circuit (Image: phase estimation)In the following simulation, we use equivalent QFTBlock in the Yao.Zoo module rather than the above chain block, it is faster than the above construction because it hides all the simulation details (yes, we are cheating :D) and get the equivalent output.using Yao\nusing Yao.Blocks\nusing Yao.Intrinsics\n\nfunction phase_estimation(reg1::DefaultRegister, reg2::DefaultRegister, U::GeneralMatrixGate{N}, nshot::Int=1) where {N}\n    M = nqubits(reg1)\n    iqft = QFT(M) |> adjoint\n    HGates = rollrepeat(M, H)\n\n    control_circuit = chain(M+N)\n    for i = 1:M\n        push!(control_circuit, control(M+N, (i,), (M+1:M+N...,)=>U))\n        if i != M\n            U = matrixgate(mat(U) * mat(U))\n        end\n    end\n\n    # calculation\n    # step1 apply hadamard gates.\n    apply!(reg1, HGates)\n    # join two registers\n    reg = join(reg1, reg2)\n    # using iqft to read out the phase\n    apply!(reg, sequence(control_circuit, focus(1:M...), iqft))\n    # measure the register (on focused bits), if the phase can be exactly represented by M qubits, only a single shot is needed.\n    res = measure(reg; nshot=nshot)\n    # inverse the bits in result due to the exchange of big and little ends, so that we can get the correct phase.\n    breflect.(M, res)./(1<<M), reg\nendHere, reg1 (Q_1-5) is used as the output space to store phase ϕ, and reg2 (Q_6-8) is the input state which corresponds to an eigenvector of oracle matrix U. The algorithm detials can be found here.In this function, HGates corresponds to circuit block in dashed box A, control_circuit corresponds to block in dashed box B. matrixgate is a factory function for GeneralMatrixGate.Here, the only difficult concept is focus, focus returns a FunctionBlock, that will make focused bits the active bits. An operator sees only active bits, and operating active space is more efficient, most importantly, it becomes much easier to integrate blocks. However, it has the potential ability to change line orders, for safety consideration, you may also need safer Concentrator.r = rand_state(6)\napply!(r, focus(4,1,2))  # or equivalently using focus!(r, [4,1,2])\nnactive(r)Then we will have a check to above functionusing LinearAlgebra: qr, Diagonal\nrand_unitary(N::Int) = qr(randn(N, N)).Q\n\nM = 5\nN = 3\n\n# prepair oracle matrix U\nV = rand_unitary(1<<N)\nphases = rand(1<<N)\nϕ = Int(0b11101)/(1<<M)\nphases[3] = ϕ  # set the phase of the 3rd eigenstate manually.\nsigns = exp.(2pi*im.*phases)\nU = V*Diagonal(signs)*V\'  # notice U is unitary\n\n# the state with phase ϕ\npsi = U[:,3]\n\nres, reg = phase_estimation(zero_state(M), register(psi), GeneralMatrixGate(U))\nprintln(\"Phase is 2π * $(res[]), the exact value is 2π * $ϕ\")"
},

{
    "location": "tutorial/Grover/#",
    "page": "Grover Search and Quantum Inference",
    "title": "Grover Search and Quantum Inference",
    "category": "page",
    "text": ""
},

{
    "location": "tutorial/Grover/#Grover-Search-and-Quantum-Inference-1",
    "page": "Grover Search and Quantum Inference",
    "title": "Grover Search and Quantum Inference",
    "category": "section",
    "text": ""
},

{
    "location": "tutorial/Grover/#Grover-Search-1",
    "page": "Grover Search and Quantum Inference",
    "title": "Grover Search",
    "category": "section",
    "text": "(Image: grover)First, we construct the reflection block R(psirangle) = 2psiranglelanglepsi-1, given we know how to construct psirangle=A0rangle. Then it equivalent to construct R(psirangle) = A(20ranglelangle 0-1)A^daggerusing Yao\nusing Yao.Blocks\nusing Test, LinearAlgebra\nusing StatsBase\n\n\"\"\"\nA way to construct oracle, e.g. inference_oracle([1,2,-3,5]) will\ninvert the sign when a qubit configuration matches: 1=>1, 2=>1, 3=>0, 5=>1.\n\"\"\"\nfunction inference_oracle(locs::Vector{Int})\n    control(locs[1:end-1], abs(locs[end]) => (locs[end]>0 ? Z : chain(phase(π), Z)))\nend\n\nfunction reflectblock(A::MatrixBlock{N}) where N\n    chain(N, A |> adjoint, inference_oracle(-collect(1:N)), A)\nend\n\nnbit = 12\nA = repeat(nbit, H)\nref = reflectblock(A)\n\n@testset \"test reflect\" begin\n    reg = rand_state(nbit)\n    ref_vec = apply!(zero_state(nbit), A) |> statevec\n    v0 = reg |> statevec\n    @test -2*(ref_vec\'*v0)*ref_vec + v0 ≈ apply!(copy(reg), ref) |> statevec\nendThen we define the oracle and target state# first, construct the oracle with desired state in the range 100-105.\noracle!(reg::DefaultRegister) = (reg.state[100:105,:]*=-1; reg)\n\n# transform it into a function block, so it can be put inside a `Sequential`.\nfb_oracle = FunctionBlock{:Oracle}(reg->oracle!(reg))\n\n\"\"\"\nratio of components in a wavefunction that flip sign under oracle.\n\"\"\"\nfunction prob_match_oracle(psi::DefaultRegister, oracle)\n    fliped_reg = apply!(register(ones(ComplexF64, 1<<nqubits(psi))), oracle)\n    match_mask = fliped_reg |> statevec |> real .< 0\n    norm(statevec(psi)[match_mask])^2\nend\n\n# uniform state as initial state\npsi0 = apply!(zero_state(nbit), A)\n\n# the number of grover steps that can make it reach first maximum overlap.\nnum_grover_step(prob::Real) = Int(round(pi/4/sqrt(prob)))-1\nniter = num_grover_step(prob_match_oracle(psi0, fb_oracle))\n\n# construct the whole circuit\ngb = sequence(sequence(fb_oracle, ref) for i = 1:niter);Now, let\'s start trainingfor (i, blk) in enumerate(gb)\n    apply!(psi0, blk)\n    overlap = prob_match_oracle(psi0, fb_oracle)\n    println(\"step $i, overlap = $overlap\")\nendThe above is the standard Grover Search algorithm, it can find target state in O(sqrt N) time, with N the size of an unordered database. Similar algorithm can be used in more useful applications, like inference, i.e. get conditional probability distribution p(xy) given p(x y).function rand_circuit(nbit::Int, ngate::Int)\n    circuit = chain(nbit)\n    gate_list = [X, H, Ry(0.3), CNOT]\n    for i = 1:ngate\n        gate = rand(gate_list)\n        push!(circuit, put(nbit, (sample(1:nbit, nqubits(gate),replace=false)...,)=>gate))\n    end\n    circuit\nend\nA = rand_circuit(nbit, 200)\npsi0 = apply!(zero_state(nbit), A)\n\n# now we want to search the subspace with [1,3,5,8,9,11,12]\n# fixed to 1 and [4,6] fixed to 0.\nevidense = [1, 3, -4, 5, -6, 8, 9, 11, 12]\n\n\"\"\"\nDoing Inference, psi is the initial state,\nthe target is to search target space with specific evidense.\ne.g. evidense [1, -3, 6] means the [1, 3, 6]-th bits take value [1, 0, 1].\n\"\"\"\noracle_infer = inference_oracle(evidense)(nqubits(psi0))\n\nniter = num_grover_step(prob_match_oracle(psi0, oracle_infer))\ngb_infer = chain(nbit, chain(oracle_infer, reflectblock(A)) for i = 1:niter);Now, let\'s start trainingfor (i, blk) in enumerate(gb_infer)\n    apply!(psi0, blk)\n    p_target = prob_match_oracle(psi0, oracle_infer)\n    println(\"step $i, overlap^2 = $p_target\")\nendHere is an application, suppose we have constructed some digits and stored it in a wave vector.using Yao.Intrinsics\n\nx1 = [0 1 0; 0 1 0; 0 1 0; 0 1 0; 0 1 0]\nx2 = [1 1 1; 0 0 1; 1 1 1; 1 0 0; 1 1 1]\nx0 = [1 1 1; 1 0 1; 1 0 1; 1 0 1; 1 1 1]\n\nnbit = 15\nv = zeros(1<<nbit)\n\n# they occur with different probabilities.\nfor (x, p) in [(x0, 0.7), (x1, 0.29), (x2,0.01)]\n    v[(x |> vec |> BitArray |> packbits)+1] = sqrt(p)\nendPlot them, you will see these digits(Image: digits)Then we construct the inference circuit. Here, we choose to use reflect to construct a ReflectBlock, instead of constructing it explicitly.rb = reflect(copy(v))\npsi0 = register(v)\n\n# we want to find the digits with the first 5 qubits [1, 0, 1, 1, 1].\nevidense = [1, -2, 3, 4, 5]\noracle_infer = inference_oracle(evidense)(nbit)\n\nniter = num_grover_step(prob_match_oracle(psi0, oracle_infer))\ngb_infer = chain(nbit, chain(oracle_infer, rb) for i = 1:niter)Now, let\'s start trainingfor (i, blk) in enumerate(gb_infer)\n    apply!(psi0, blk)\n    p_target = prob_match_oracle(psi0, oracle_infer)\n    println(\"step $i, overlap^2 = $p_target\")\nendThe result ispl = psi0 |> probs\nconfig = findfirst(pi->pi>0.5, pl) - 1 |> bitarray(nbit)\nres = reshape(config, 5,3)It is 2 ~(Image: infer)Congratuations! You get state of art quantum inference circuit!"
},

{
    "location": "tutorial/QCBM/#",
    "page": "Quantum Circuit Born Machine",
    "title": "Quantum Circuit Born Machine",
    "category": "page",
    "text": "EditURL = \"https://github.com/QuantumBFS/Yao.jl/blob/master/../../../../build/QuantumBFS/Yao.jl/docs/src/tutorial/QCBM.jl\""
},

{
    "location": "tutorial/QCBM/#Quantum-Circuit-Born-Machine-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Quantum Circuit Born Machine",
    "category": "section",
    "text": "Reference: Jin-Guo Liu, Lei Wang (2018) Differentiable Learning of Quantum Circuit Born Machineusing Yao, Yao.Blocks\nusing LinearAlgebra"
},

{
    "location": "tutorial/QCBM/#Training-target-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Training target",
    "category": "section",
    "text": "A gaussian distributionf(x left mu sigma^2right) = frac1sqrt2pisigma^2 e^-frac(x-mu)^22sigma^2function gaussian_pdf(x, μ::Real, σ::Real)\n    pl = @. 1 / sqrt(2pi * σ^2) * exp(-(x - μ)^2 / (2 * σ^2))\n    pl / sum(pl)\nend\npg = gaussian_pdf(1:1<<6, 1<<5-0.5, 1<<4);This distribution looks like (Image: Gaussian Distribution)"
},

{
    "location": "tutorial/QCBM/#Build-Circuits-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Build Circuits",
    "category": "section",
    "text": ""
},

{
    "location": "tutorial/QCBM/#Building-Blocks-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Building Blocks",
    "category": "section",
    "text": "Gates are grouped to become a layer in a circuit, this layer can be Arbitrary Rotation or CNOT entangler. Which are used as our basic building blocks of Born Machines.(Image: differentiable ciruit)"
},

{
    "location": "tutorial/QCBM/#Arbitrary-Rotation-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Arbitrary Rotation",
    "category": "section",
    "text": "Arbitrary Rotation is built with Rotation Gate on Z, Rotation Gate on X and Rotation Gate on Z:Rz(theta) cdot Rx(theta) cdot Rz(theta)Since our input will be a 0dots 0rangle state. The first layer of arbitrary rotation can just use Rx(theta) cdot Rz(theta) and the last layer of arbitrary rotation could just use Rz(theta)cdot Rx(theta)In 幺, every Hilbert operator is a block type, this includes all quantum gates and quantum oracles. In general, operators appears in a quantum circuit can be divided into Composite Blocks and Primitive Blocks.We follow the low abstraction principle and thus each block represents a certain approach of calculation. The simplest Composite Block is a Chain Block, which chains other blocks (oracles) with the same number of qubits together. It is just a simple mathematical composition of operators with same size. e.g.textchain(X Y Z) iff X cdot Y cdot ZWe can construct an arbitrary rotation block by chain Rz, Rx, Rz together.chain(Rz(0), Rx(0), Rz(0))Rx, Ry and Rz will construct new rotation gate, which are just shorthands for rot(X, 0.0), etc.Then, let\'s chain them uplayer(nbit::Int, x::Symbol) = layer(nbit, Val(x))\nlayer(nbit::Int, ::Val{:first}) = chain(nbit, put(i=>chain(Rx(0), Rz(0))) for i = 1:nbit);Here, we do not need to feed the first nbit parameter into put. All factory methods can be lazy evaluate the first arguements, which is the number of qubits. It will return a lambda function that requires a single interger input. The instance of desired block will only be constructed until all the information is filled. When you filled all the information in somewhere of the declaration, 幺 will be able to infer the others. We will now define the rest of rotation layerslayer(nbit::Int, ::Val{:last}) = chain(nbit, put(i=>chain(Rz(0), Rx(0))) for i = 1:nbit)\nlayer(nbit::Int, ::Val{:mid}) = chain(nbit, put(i=>chain(Rz(0), Rx(0), Rz(0))) for i = 1:nbit);"
},

{
    "location": "tutorial/QCBM/#CNOT-Entangler-1",
    "page": "Quantum Circuit Born Machine",
    "title": "CNOT Entangler",
    "category": "section",
    "text": "Another component of quantum circuit born machine is several CNOT operators applied on different qubits.entangler(pairs) = chain(control([ctrl, ], target=>X) for (ctrl, target) in pairs);We can then define such a born machinefunction build_circuit(n::Int, nlayer::Int, pairs)\n    circuit = chain(n)\n    push!(circuit, layer(n, :first))\n\n    for i = 1:(nlayer - 1)\n        push!(circuit, cache(entangler(pairs)))\n        push!(circuit, layer(n, :mid))\n    end\n\n    push!(circuit, cache(entangler(pairs)))\n    push!(circuit, layer(n, :last))\n\n    circuit\nend;We use the method cache here to tag the entangler block that it should be cached after its first run, because it is actually a constant oracle. Let\'s see what will be constructedbuild_circuit(4, 1, [1=>2, 2=>3, 3=>4]) |> autodiff(:QC)RotationGates inside this circuit are automatically marked by [̂∂], which means parameters inside are diferentiable. autodiff has two modes, one is autodiff(:QC), which means quantum differentiation with simulation complexity O(M^2) (M is the number of parameters), the other is classical backpropagation autodiff(:BP) with simulation coplexity O(M).Let\'s define a circuit to use latercircuit = build_circuit(6, 10, [1=>2, 3=>4, 5=>6, 2=>3, 4=>5, 6=>1]) |> autodiff(:QC)\ndispatch!(circuit, :random);Here, the function autodiff(:QC) will mark rotation gates in a circuit as differentiable automatically."
},

{
    "location": "tutorial/QCBM/#MMD-Loss-and-Gradients-1",
    "page": "Quantum Circuit Born Machine",
    "title": "MMD Loss & Gradients",
    "category": "section",
    "text": "The MMD loss is describe below:beginaligned\nmathcalL = left sum_x p theta(x) phi(x) - sum_x pi(x) phi(x) right^2\n            = langle K(x y) rangle_x sim p_theta ysim p_theta - 2 langle K(x y) rangle_xsim p_theta ysim pi + langle K(x y) rangle_xsimpi ysimpi\nendalignedWe will use a squared exponential kernel here.struct RBFKernel\n    sigma::Float64\n    matrix::Matrix{Float64}\nend\n\n\"\"\"get kernel matrix\"\"\"\nkmat(mbf::RBFKernel) = mbf.matrix\n\n\"\"\"statistic functional for kernel matrix\"\"\"\nkernel_expect(kernel::RBFKernel, px::Vector, py::Vector=px) = px\' * kmat(kernel) * py;Now let\'s define the RBF kernel matrix used in calculationfunction rbf_kernel(basis, σ::Real)\n    dx2 = (basis .- basis\').^2\n    RBFKernel(σ, exp.(-1/2σ * dx2))\nend\n\nkernel = rbf_kernel(0:1<<6-1, 0.25);Next, we build a QCBM setup, which is a combination of circuit, kernel and target probability distribution ptrain Its loss function is MMD loss, if and only if it is 0, the output probability of circuit matches ptrain exactly.struct QCBM{BT<:AbstractBlock}\n    circuit::BT\n    kernel::RBFKernel\n    ptrain::Vector{Float64}\nend\n\n\"\"\"get wave function\"\"\"\npsi(qcbm::QCBM) = zero_state(qcbm.circuit |> nqubits) |> qcbm.circuit\n\n\"\"\"extract probability dierctly\"\"\"\nYao.probs(qcbm::QCBM) = qcbm |> psi |> probs\n\n\"\"\"the loss function\"\"\"\nfunction mmd_loss(qcbm, p=qcbm|>probs)\n    p = p - qcbm.ptrain\n    kernel_expect(qcbm.kernel, p, p)\nend;problem setupqcbm = QCBM(circuit, kernel, pg);"
},

{
    "location": "tutorial/QCBM/#Gradients-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Gradients",
    "category": "section",
    "text": "the gradient of MMD loss isbeginaligned\nfracpartial mathcalLpartial theta^i_l = langle K(x y) rangle_xsim p_theta^+ ysim p_theta - langle K(x y) rangle_xsim p_theta^- ysim p_theta\n- langle K(x y) rangle _xsim p_theta^+ ysimpi + langle K(x y) rangle_xsim p_theta^- ysimpi\nendalignedfunction mmdgrad(qcbm::QCBM, dbs; p0::Vector)\n    statdiff(()->probs(qcbm) |> as_weights, dbs, StatFunctional(kmat(qcbm.kernel)), initial=p0 |> as_weights) -\n        2*statdiff(()->probs(qcbm) |> as_weights, dbs, StatFunctional(kmat(qcbm.kernel)*qcbm.ptrain))\nend;"
},

{
    "location": "tutorial/QCBM/#Optimizer-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Optimizer",
    "category": "section",
    "text": "We will use the Adam optimizer. Since we don\'t want you to install another package for this, the following code for this optimizer is copied from Knet.jlReference: Kingma, D. P., & Ba, J. L. (2015). Adam: a Method for Stochastic Optimization. International Conference on Learning Representations, 1–13.mutable struct Adam\n    lr::AbstractFloat\n    gclip::AbstractFloat\n    beta1::AbstractFloat\n    beta2::AbstractFloat\n    eps::AbstractFloat\n    t::Int\n    fstm\n    scndm\nend\n\nAdam(; lr=0.001, gclip=0, beta1=0.9, beta2=0.999, eps=1e-8)=Adam(lr, gclip, beta1, beta2, eps, 0, nothing, nothing)\n\nfunction update!(w, g, p::Adam)\n    gclip!(g, p.gclip)\n    if p.fstm===nothing; p.fstm=zero(w); p.scndm=zero(w); end\n    p.t += 1\n    lmul!(p.beta1, p.fstm)\n    BLAS.axpy!(1-p.beta1, g, p.fstm)\n    lmul!(p.beta2, p.scndm)\n    BLAS.axpy!(1-p.beta2, g .* g, p.scndm)\n    fstm_corrected = p.fstm / (1 - p.beta1 ^ p.t)\n    scndm_corrected = p.scndm / (1 - p.beta2 ^ p.t)\n    BLAS.axpy!(-p.lr, @.(fstm_corrected / (sqrt(scndm_corrected) + p.eps)), w)\nend\n\nfunction gclip!(g, gclip)\n    if gclip == 0\n        g\n    else\n        gnorm = vecnorm(g)\n        if gnorm <= gclip\n            g\n        else\n            BLAS.scale!(gclip/gnorm, g)\n        end\n    end\nend\noptim = Adam(lr=0.1);"
},

{
    "location": "tutorial/QCBM/#Start-Training-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Start Training",
    "category": "section",
    "text": "We define an iterator called QCBMOptimizer. We want to realize some interface likefor x in qo\n    # runtime result analysis\nendAlthough such design makes the code a bit more complicated, but one will benefit from this interfaces when doing run time analysis, like keeping track of the loss.struct QCBMOptimizer\n    qcbm::QCBM\n    optimizer\n    dbs\n    params::Vector\n    QCBMOptimizer(qcbm::QCBM, optimizer) = new(qcbm, optimizer, collect(qcbm.circuit, AbstractDiff), parameters(qcbm.circuit))\nendIn the initialization of QCBMOptimizer instance, we collect all differentiable units into a sequence dbs for furture use.iterator interface To support iteration operations, Base.iterate should be implementedfunction Base.iterate(qo::QCBMOptimizer, state::Int=1)\n    p0 = qo.qcbm |> probs\n    grad = mmdgrad.(Ref(qo.qcbm), qo.dbs, p0=p0)\n    update!(qo.params, grad, qo.optimizer)\n    dispatch!(qo.qcbm.circuit, qo.params)\n    (p0, state+1)\nendIn each iteration, the iterator will return the generated probability distribution in current step. During each iteration step, we broadcast mmdgrad function over dbs to obtain all gradients. Here, To avoid the QCBM instance from being broadcasted, we wrap it with Ref to create a reference for it. The training of the quantum circuit is simple, just iterate through the steps.history = Float64[]\nfor (k, p) in enumerate(QCBMOptimizer(qcbm, optim))\n    curr_loss = mmd_loss(qcbm, p)\n    push!(history, curr_loss)\n    k%5 == 0 && println(\"k = \", k, \" loss = \", curr_loss)\n    k >= 50 && break\nendThe training history looks like (Image: History)and the learnt distribution (Image: Learnt Distribution)This page was generated using Literate.jl."
},

{
    "location": "man/yao/#",
    "page": "Yao",
    "title": "Yao",
    "category": "page",
    "text": ""
},

{
    "location": "man/yao/#Yao.Yao",
    "page": "Yao",
    "title": "Yao.Yao",
    "category": "module",
    "text": "Extensible Framework for Quantum Algorithm Design for Humans.\n\n简单易用可扩展的量子算法设计框架。\n\n\n\n\n\n"
},

{
    "location": "man/yao/#Yao.幺",
    "page": "Yao",
    "title": "Yao.幺",
    "category": "module",
    "text": "Extensible Framework for Quantum Algorithm Design for Humans.\n\n简单易用可扩展的量子算法设计框架。\n\n幺 means unitary in Chinese.\n\n\n\n\n\n"
},

{
    "location": "man/yao/#Yao.invorder-Tuple{Any}",
    "page": "Yao",
    "title": "Yao.invorder",
    "category": "method",
    "text": "invorder(reg) -> reg\n\nInverse the order of qubits.\n\n\n\n\n\n"
},

{
    "location": "man/yao/#Yao-1",
    "page": "Yao",
    "title": "Yao",
    "category": "section",
    "text": "(Image: Framework-Structure)Modules = [Yao]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/interfaces/#",
    "page": "Interfaces",
    "title": "Interfaces",
    "category": "page",
    "text": "CurrentModule = Yao.Interfaces"
},

{
    "location": "man/interfaces/#Yao.Blocks.H",
    "page": "Interfaces",
    "title": "Yao.Blocks.H",
    "category": "constant",
    "text": "H\n\nThe Hadamard gate acts on a single qubit. It maps the basis state 0rangle to frac0rangle + 1ranglesqrt2 and 1rangle to frac0rangle - 1ranglesqrt2, which means that a measurement will have equal probabilities to become 1 or 0. It is representated by the Hadamard matrix:\n\nH = frac1sqrt2 beginpmatrix\n1  1 \n1  -1\nendpmatrix\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.X",
    "page": "Interfaces",
    "title": "Yao.Blocks.X",
    "category": "constant",
    "text": "X\n\nThe Pauli-X gate acts on a single qubit. It is the quantum equivalent of the NOT gate for classical computers (with respect to the standard basis 0rangle, 1rangle). It is represented by the Pauli X matrix:\n\nX = beginpmatrix\n0  1\n1  0\nendpmatrix\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.Y",
    "page": "Interfaces",
    "title": "Yao.Blocks.Y",
    "category": "constant",
    "text": "Y\n\nThe Pauli-Y gate acts on a single qubit. It equates to a rotation around the Y-axis of the Bloch sphere by pi radians. It maps 0rangle to i1rangle and 1rangle to -i0rangle. It is represented by the Pauli Y matrix:\n\nY = beginpmatrix\n0  -i\ni  0\nendpmatrix\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.Z",
    "page": "Interfaces",
    "title": "Yao.Blocks.Z",
    "category": "constant",
    "text": "Z\n\nThe Pauli-Z gate acts on a single qubit. It equates to a rotation around the Z-axis of the Bloch sphere by pi radians. Thus, it is a special case of a phase shift gate (see shift) with theta = pi. It leaves the basis state 0rangle unchanged and maps 1rangle to -1rangle. Due to this nature, it is sometimes called phase-flip. It is represented by the Pauli Z matrix:\n\nZ = beginpmatrix\n1  0\n0  -1\nendpmatrix\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.InvOrder",
    "page": "Interfaces",
    "title": "Yao.Interfaces.InvOrder",
    "category": "constant",
    "text": "InvOrder\n\nReturn a FunctionBlock of inversing the order.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Reset",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Reset",
    "category": "constant",
    "text": "Reset\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.StatFunctional",
    "page": "Interfaces",
    "title": "Yao.Interfaces.StatFunctional",
    "category": "type",
    "text": "StatFunctional{N, AT}\nStatFunctional(array::AT<:Array) -> StatFunctional{N, <:Array}\nStatFunctional{N}(func::AT<:Function) -> StatFunctional{N, <:Function}\n\nstatistic functional, i.e.     * if AT is an array, A[i,j,k...], it is defined on finite Hilbert space, which is ∫A[i,j,k...]p[i]p[j]p[k]...     * if AT is a function, F(xᵢ,xⱼ,xₖ...), this functional is 1/C(r,n)... ∑ᵢⱼₖ...F(xᵢ,xⱼ,xₖ...), see U-statistics for detail.\n\nReferences:     U-statistics, http://personal.psu.edu/drh20/asymp/fall2006/lectures/ANGELchpt10.pdf\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.@fn",
    "page": "Interfaces",
    "title": "Yao.Interfaces.@fn",
    "category": "macro",
    "text": "macro fn([name,] f)\n\nDefine a in-place function on a register inside circuits.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Rx",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Rx",
    "category": "function",
    "text": "Rx([type=Yao.DefaultType], theta) -> RotationGate{1, type, X}\n\nReturns a rotation X gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Ry",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Ry",
    "category": "function",
    "text": "Ry([type=Yao.DefaultType], theta) -> RotationGate{1, type, Y}\n\nReturns a rotation Y gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Rz",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Rz",
    "category": "function",
    "text": "Rz([type=Yao.DefaultType], theta) -> RotationGate{1, type, Z}\n\nReturns a rotation Z gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.add",
    "page": "Interfaces",
    "title": "Yao.Interfaces.add",
    "category": "function",
    "text": "add([T], n::Int) -> AddBlock\nadd([n], blocks) -> AddBlock\nadd(blocks...) -> AddBlock\n\nReturns a AddBlock. This factory method can be called lazily if you missed the total number of qubits.\n\nThis adds several blocks with the same size together.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.addbit-Tuple{Int64}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.addbit",
    "category": "method",
    "text": "addbit(n::Int) -> FunctionBlock{:AddBit}\n\nReturn a FunctionBlock of adding n bits.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.autodiff",
    "page": "Interfaces",
    "title": "Yao.Interfaces.autodiff",
    "category": "function",
    "text": "autodiff(mode::Symbol, block::AbstractBlock) -> AbstractBlock\nautodiff(mode::Symbol) -> Function\n\nautomatically mark differentiable items in a block tree as differentiable.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.chain",
    "page": "Interfaces",
    "title": "Yao.Interfaces.chain",
    "category": "function",
    "text": "chain([T], n::Int) -> ChainBlock\nchain([n], blocks) -> ChainBlock\nchain(blocks...) -> ChainBlock\n\nReturns a ChainBlock. This factory method can be called lazily if you missed the total number of qubits.\n\nThis chains several blocks with the same size together.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.concentrate-Tuple{Int64,AbstractBlock,Any}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.concentrate",
    "category": "method",
    "text": "concentrate(nbit::Int, block::AbstractBlock, addrs) -> Concentrator{nbit}\n\nconcentrate blocks on serveral addrs.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.control",
    "page": "Interfaces",
    "title": "Yao.Interfaces.control",
    "category": "function",
    "text": "control([total], controls, target) -> ControlBlock\n\nConstructs a ControlBlock\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.matrixgate-Tuple{AbstractArray{T,2} where T}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.matrixgate",
    "category": "method",
    "text": "matrixgate(matrix::AbstractMatrix) -> GeneralMatrixGate\nmatrixgate(matrix::MatrixBlock) -> GeneralMatrixGate\n\nConstruct a general matrix gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.numdiff-Tuple{Any,AbstractDiff}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.numdiff",
    "category": "method",
    "text": "numdiff(loss, diffblock::AbstractDiff; δ::Real=1e-2)\n\nNumeric differentiation.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.opdiff-Tuple{Any,AbstractDiff,MatrixBlock}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.opdiff",
    "category": "method",
    "text": "opdiff(psifunc, diffblock::AbstractDiff, op::MatrixBlock)\n\nOperator differentiation.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.paulistring",
    "page": "Interfaces",
    "title": "Yao.Interfaces.paulistring",
    "category": "function",
    "text": "paulistring([n], blocks::PauliGate...) -> PauliString\npaulistring([n], blocks::Pair{Int, PauliGate}...) -> PauliString\n\nReturns a PauliString. This factory method can be called lazily if you missed the total number of qubits.\n\nThis krons several pauli gates, either dict (more flexible) like input and chain like input are allowed. i.e. paulistring(3, X, Y, Z) is equivalent to paulistring(3, 1=>X, 2=>Y, 3=>Z)\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.phase",
    "page": "Interfaces",
    "title": "Yao.Interfaces.phase",
    "category": "function",
    "text": "phase([type=Yao.DefaultType], theta) -> PhaseGate{:global}\n\nReturns a global phase gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.put-Union{Tuple{M}, Tuple{Int64,Pair{Tuple{Vararg{Int64,M}},#s360} where #s360<:AbstractBlock}} where M",
    "page": "Interfaces",
    "title": "Yao.Interfaces.put",
    "category": "method",
    "text": "put([total::Int, ]pa::Pair) -> PutBlock{total}\n\nput a block at the specific position(s), can be lazy constructed.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.reflect",
    "page": "Interfaces",
    "title": "Yao.Interfaces.reflect",
    "category": "function",
    "text": "reflect(mirror::DefaultRegister{1}) -> ReflectBlock\nreflect(mirror::Vector) -> ReflectBlock\n\nReturn an ReflectBlock along with state vector mirror as the axis.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.roll",
    "page": "Interfaces",
    "title": "Yao.Interfaces.roll",
    "category": "function",
    "text": "roll([n::Int, ], blocks...,) -> Roller{n}\n\nConstruct a Roller block, which is a faster than KronBlock to calculate similar small blocks tile on the whole address.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.rollrepeat",
    "page": "Interfaces",
    "title": "Yao.Interfaces.rollrepeat",
    "category": "function",
    "text": "rollrepeat([n::Int,] block::MatrixBlock) -> Roller{n}\n\nConstruct a Roller block, which is a faster than KronBlock to calculate similar small blocks tile on the whole address.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.rot",
    "page": "Interfaces",
    "title": "Yao.Interfaces.rot",
    "category": "function",
    "text": "rot([type=Yao.DefaultType], U, theta) -> RotationGate{N, type, U}\n\nReturns an arbitrary rotation gate on U.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.sequence",
    "page": "Interfaces",
    "title": "Yao.Interfaces.sequence",
    "category": "function",
    "text": "Returns a Sequential block. This factory method can be called lazily if you missed the total number of qubits.\n\nThis is the loose version of sequence, that does not support the mat related interfaces.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.shift",
    "page": "Interfaces",
    "title": "Yao.Interfaces.shift",
    "category": "function",
    "text": "shift([type=Yao.DefaultType], theta) -> PhaseGate{:shift}\n\nReturns a phase shift gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.statdiff-Tuple{Any,AbstractDiff,StatFunctional{2,AT} where AT}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.statdiff",
    "category": "method",
    "text": "statdiff(probfunc, diffblock::AbstractDiff, stat::StatFunctional{<:Any, <:AbstractArray}; initial::AbstractVector=probfunc())\nstatdiff(samplefunc, diffblock::AbstractDiff, stat::StatFunctional{<:Any, <:Function}; initial::AbstractVector=samplefunc())\n\nDifferentiation for statistic functionals.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.swap",
    "page": "Interfaces",
    "title": "Yao.Interfaces.swap",
    "category": "function",
    "text": "swap([n], [type], line1, line2) -> Swap\n\nReturns a swap gate on line1 and line2\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.timeevolve",
    "page": "Interfaces",
    "title": "Yao.Interfaces.timeevolve",
    "category": "function",
    "text": "timeevolve({block::MatrixBlock}, t::Real; tol::Real=1e-7) -> TimeEvolution\n\nMake a time machine! If block is not provided, it will become lazy.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.XGate",
    "page": "Interfaces",
    "title": "Yao.Blocks.XGate",
    "category": "type",
    "text": "XGate{T} <: ConstantGate{1, T}\n\nThe block type for Pauli-X gate. See docs for X for more information.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.YGate",
    "page": "Interfaces",
    "title": "Yao.Blocks.YGate",
    "category": "type",
    "text": "YGate{T} <: ConstantGate{1, T}\n\nThe block type for Pauli-Y gate. See docs for Y for more information.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.ZGate",
    "page": "Interfaces",
    "title": "Yao.Blocks.ZGate",
    "category": "type",
    "text": "ZGate{T} <: ConstantGate{1, T}\n\nThe block type for Pauli-Z gate. See docs for Z for more information.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Base.kron-Tuple{Int64,Vararg{Pair{Int64,#s360} where #s360<:MatrixBlock,N} where N}",
    "page": "Interfaces",
    "title": "Base.kron",
    "category": "method",
    "text": "kron([total::Int, ]block0::Pair, blocks::Union{MatrixBlock, Pair}...,) -> KronBlock{total}\n\ncreate a KronBlock with a list of blocks or tuple of heads and blocks. If total is not provided, return a lazy constructor.\n\nExample\n\nkron(4, 1=>X, 3=>Z, 4=>Y)\n\nThis will automatically generate a block list looks like\n\n1 -- [X] --\n2 ---------\n3 -- [Z] --\n4 -- [Y] --\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Base.repeat-Tuple{Int64,MatrixBlock,Any}",
    "page": "Interfaces",
    "title": "Base.repeat",
    "category": "method",
    "text": "repeat([n::Int,] x::MatrixBlock, [addrs]) -> RepeatedBlock{n}\n\nConstruct a RepeatedBlock, if n (the number of qubits) not supplied, using lazy evaluation. If addrs not supplied, blocks will fill the qubit space.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Interfaces-1",
    "page": "Interfaces",
    "title": "Interfaces",
    "category": "section",
    "text": "Modules = [Interfaces]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/registers/#",
    "page": "Registers",
    "title": "Registers",
    "category": "page",
    "text": ""
},

{
    "location": "man/registers/#Registers-1",
    "page": "Registers",
    "title": "Registers",
    "category": "section",
    "text": "Quantum circuits process quantum states. A quantum state being processing by a quantum circuit will be stored on a quantum register. In Yao we provide several types for registers. The default type for registers is the Yao.Registers.DefaultRegister.You can directly use factory method register"
},

{
    "location": "man/registers/#Storage-1",
    "page": "Registers",
    "title": "Storage",
    "category": "section",
    "text": ""
},

{
    "location": "man/registers/#LDT-format-1",
    "page": "Registers",
    "title": "LDT format",
    "category": "section",
    "text": "Concepturely, a wave function psirangle can be represented in a low dimentional tensor (LDT) format of order-3, L(f, r, b).f: focused (i.e. operational) dimensions\nr: remaining dimensions\nb: batch dimension.For simplicity, let\'s ignore batch dimension for the momentum, we havepsirangle = sumlimits_xy L(x y ) jrangleirangleGiven a configuration x (in operational space), we want get the i-th bit using (x<<i) & 0x1, which means putting the small end the qubit with smaller index. In this representation L(x) will get return langle xpsirangle.note: Note\nWhy not the other convension: Using the convention of putting 1st bit on the big end will need to know the total number of qubits n in order to know such positional information."
},

{
    "location": "man/registers/#HDT-format-1",
    "page": "Registers",
    "title": "HDT format",
    "category": "section",
    "text": "Julia storage is column major, if we reshape the wave function to a shape of 2times2times  times2 and get the HDT (high dimensional tensor) format representation H, we can use H(x_1 x_2  x_3) to get langle xpsirangle."
},

{
    "location": "man/registers/#Operations-1",
    "page": "Registers",
    "title": "Operations",
    "category": "section",
    "text": ""
},

{
    "location": "man/registers/#Kronecker-product-of-operators-1",
    "page": "Registers",
    "title": "Kronecker product of operators",
    "category": "section",
    "text": "In order to put small bits on little end, the Kronecker product is O = o_n otimes ldots otimes o_2 otimes o_1 where the subscripts are qubit indices."
},

{
    "location": "man/registers/#Measurements-1",
    "page": "Registers",
    "title": "Measurements",
    "category": "section",
    "text": "Measure means sample and projection."
},

{
    "location": "man/registers/#Sample-1",
    "page": "Registers",
    "title": "Sample",
    "category": "section",
    "text": "Suppose we want to measure operational subspace, we can first getp(x) = langle xpsirangle^2 = sumlimits_y L(x y )^2Then we sample an asim p(x). If we just sample and don\'t really measure (change wave function), its over."
},

{
    "location": "man/registers/#Projection-1",
    "page": "Registers",
    "title": "Projection",
    "category": "section",
    "text": "psirangle = sum_y L(a y )sqrtp(a) arangle yrangleGood! then we can just remove the operational qubit space since x and y spaces are totally decoupled and x is known as in state a, then we getpsirangle_r = sum_y l(0 y ) yranglewhere l = L(a:a, :, :)/sqrt(p(a))."
},

{
    "location": "man/registers/#Yao.Registers.AbstractRegister",
    "page": "Registers",
    "title": "Yao.Registers.AbstractRegister",
    "category": "type",
    "text": "AbstractRegister{B, T}\n\nabstract type that registers will subtype from. B is the batch size, T is the data type.\n\nRequired Properties\n\nProperty Description default\nviewbatch(reg,i) get the view of slice in batch dimension. \nnqubits(reg) get the total number of qubits. \nnactive(reg) get the number of active qubits. \nstate(reg) get the state of this register. It always return the matrix stored inside. \n(optional)  \nnremain(reg) get the number of remained qubits. nqubits - nactive\ndatatype(reg) get the element type Julia should use to represent amplitude) T\nnbatch(reg) get the number of batch. B\nlength(reg) alias of nbatch, for interfacing. B\n\nRequired Methods\n\nMultiply\n\n*(op, reg)\n\ndefine how operator op act on this register. This is quite useful when there is a special approach to apply an operator on this register. (e.g a register with no batch, or a register with a MPS state, etc.)\n\nnote: Note\nbe careful, generally, operators can only be applied to a register, thus we should only overload this operation and do not overload *(reg, op).\n\nPack Address\n\npack addrs together to the first k-dimensions.\n\nExample\n\nGiven a register with dimension [2, 3, 1, 5, 4], we pack [5, 4] to the first 2 dimensions. We will get [5, 4, 2, 3, 1].\n\nFocus Address\n\nfocus!(reg, range)\n\nmerge address in range together as one dimension (the active space).\n\nExample\n\nGiven a register with dimension (2^4)x3 and address [1, 2, 3, 4], we focus address [3, 4], will pack [3, 4] together and merge them as the active space. Then we will have a register with size 2^2x(2^2x3), and address [3, 4, 1, 2].\n\nInitializers\n\nInitializers are functions that provide specific quantum states, e.g zero states, random states, GHZ states and etc.\n\nregister(::Type{RT}, raw, nbatch)\n\nan general initializer for input raw state array.\n\nregister(::Val{InitMethod}, ::Type{RT}, ::Type{T}, n, nbatch)\n\ninit register type RT with InitMethod type (e.g Val{:zero}) with element type T and total number qubits n with nbatch. This will be auto-binded to some shortcuts like zero_state, rand_state.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.DefaultRegister",
    "page": "Registers",
    "title": "Yao.Registers.DefaultRegister",
    "category": "type",
    "text": "DefaultRegister{B, T} <: AbstractRegister{B, T}\n\nDefault type for a quantum register. It contains a dense array that represents a batched quantum state with batch size B of type T.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.DensityMatrix",
    "page": "Registers",
    "title": "Yao.Registers.DensityMatrix",
    "category": "type",
    "text": "DensityMatrix{B, T, MT<:AbstractArray{T, 3}}\nDensityMatrix(state) -> DensityMatrix\n\nDensity Matrix.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.@bit_str-Tuple{Any}",
    "page": "Registers",
    "title": "Yao.Registers.@bit_str",
    "category": "macro",
    "text": "@bit_str -> BitStr\n\nConstruct a bit string. such as bit\"0000\". The bit strings also supports string concat. Just use it like normal strings.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#LinearAlgebra.normalize!",
    "page": "Registers",
    "title": "LinearAlgebra.normalize!",
    "category": "function",
    "text": "normalize!(r::AbstractRegister) -> AbstractRegister\n\nReturn the register with normalized state.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Intrinsics.hypercubic-Union{Tuple{DefaultRegister{B,T,MT} where MT<:AbstractArray{T,2} where T}, Tuple{B}} where B",
    "page": "Registers",
    "title": "Yao.Intrinsics.hypercubic",
    "category": "method",
    "text": "hypercubic(r::DefaultRegister) -> AbstractArray\n\nReturn the hypercubic form (high dimensional tensor) of this register, only active qubits are considered.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.addbit!",
    "page": "Registers",
    "title": "Yao.Registers.addbit!",
    "category": "function",
    "text": "addbit!(r::AbstractRegister, n::Int) -> AbstractRegister\naddbit!(n::Int) -> Function\n\naddbit the register by n bits in state |0>. i.e. |psi> -> |000> ⊗ |psi>, addbit bits have higher indices. If only an integer is provided, then perform lazy evaluation.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.density_matrix",
    "page": "Registers",
    "title": "Yao.Registers.density_matrix",
    "category": "function",
    "text": "density_matrix(register)\n\nReturns the density matrix of this register.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.fidelity",
    "page": "Registers",
    "title": "Yao.Registers.fidelity",
    "category": "function",
    "text": "fidelity(reg1::AbstractRegister, reg2::AbstractRegister) -> Vector\n\nReturn the fidelity between two states.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.focus!",
    "page": "Registers",
    "title": "Yao.Registers.focus!",
    "category": "function",
    "text": "focus!(reg::DefaultRegister, bits::Ints) -> DefaultRegister\nfocus!(locs::Int...) -> Function\n\nFocus register on specified active bits.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.focus!-Tuple{Any,DefaultRegister,Any}",
    "page": "Registers",
    "title": "Yao.Registers.focus!",
    "category": "method",
    "text": "focus!(func, reg::DefaultRegister, locs) -> DefaultRegister\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.invorder!",
    "page": "Registers",
    "title": "Yao.Registers.invorder!",
    "category": "function",
    "text": "invorder!(reg::AbstractRegister) -> AbstractRegister\n\nInverse the order of lines inplace.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.isnormalized",
    "page": "Registers",
    "title": "Yao.Registers.isnormalized",
    "category": "function",
    "text": "isnormalized(reg::AbstractRegister) -> Bool\n\nReturn true if a register is normalized else false.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.measure!-Union{Tuple{AbstractRegister{B,T} where T}, Tuple{B}} where B",
    "page": "Registers",
    "title": "Yao.Registers.measure!",
    "category": "method",
    "text": "measure!(reg::AbstractRegister; [locs]) -> Int\n\nmeasure and collapse to result state.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.measure-Tuple{AbstractRegister{1,T} where T}",
    "page": "Registers",
    "title": "Yao.Registers.measure",
    "category": "method",
    "text": "measure(register, [locs]; [nshot=1]) -> Vector\n\nmeasure active qubits for nshot times.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.measure_remove!-Union{Tuple{AbstractRegister{B,T} where T}, Tuple{B}} where B",
    "page": "Registers",
    "title": "Yao.Registers.measure_remove!",
    "category": "method",
    "text": "measure_remove!(register; [locs]) -> Int\n\nmeasure the active qubits of this register and remove them.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.measure_reset!-Union{Tuple{AbstractRegister{B,T} where T}, Tuple{B}} where B",
    "page": "Registers",
    "title": "Yao.Registers.measure_reset!",
    "category": "method",
    "text": "measure_and_reset!(reg::AbstractRegister; [locs], [val=0]) -> Int\n\nmeasure and set the register to specific value.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.oneto-Union{Tuple{DefaultRegister{B,T,MT} where MT<:AbstractArray{T,2} where T}, Tuple{B}, Tuple{DefaultRegister{B,T,MT} where MT<:AbstractArray{T,2} where T,Int64}} where B",
    "page": "Registers",
    "title": "Yao.Registers.oneto",
    "category": "method",
    "text": "oneto({reg::DefaultRegister}, n::Int=nqubits(reg)) -> DefaultRegister\n\nReturn a register with first 1:n bits activated, reg here can be lazy.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.probs",
    "page": "Registers",
    "title": "Yao.Registers.probs",
    "category": "function",
    "text": "probs(r::AbstractRegister)\n\nReturns the probability distribution in computation basis xψ^2.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.probs-Union{Tuple{DensityMatrix{B,T,MT} where MT<:AbstractArray{T,3}}, Tuple{T}, Tuple{B}} where T where B",
    "page": "Registers",
    "title": "Yao.Registers.probs",
    "category": "method",
    "text": "probs(dm::DensityMatrix{B, T}) where {B,T}\n\nReturn probability from density matrix.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.product_state-Union{Tuple{T}, Tuple{Type{T},Int64,Integer}, Tuple{Type{T},Int64,Integer,Int64}} where T",
    "page": "Registers",
    "title": "Yao.Registers.product_state",
    "category": "method",
    "text": "product_state([::Type{T}], n::Int, config::Int, nbatch::Int=1) -> DefaultRegister\n\na product state on given configuration config, e.g. product_state(ComplexF64, 5, 0) will give a zero state on a 5 qubit register.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.rand_state-Union{Tuple{T}, Tuple{Type{T},Int64}, Tuple{Type{T},Int64,Int64}} where T",
    "page": "Registers",
    "title": "Yao.Registers.rand_state",
    "category": "method",
    "text": "rand_state([::Type{T}], n::Int, nbatch::Int=1) -> DefaultRegister\n\nhere, random complex numbers are generated using randn(ComplexF64).\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.rank3-Union{Tuple{DefaultRegister{B,T,MT} where MT<:AbstractArray{T,2} where T}, Tuple{B}} where B",
    "page": "Registers",
    "title": "Yao.Registers.rank3",
    "category": "method",
    "text": "rank3(reg::DefaultRegister) -> Array{T, 3}\n\nReturn the rank 3 tensor representation of state, the 3 dimensions are (activated space, remaining space, batch dimension).\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.register",
    "page": "Registers",
    "title": "Yao.Registers.register",
    "category": "function",
    "text": "register([type], bit_str, [nbatch=1]) -> DefaultRegister\n\nReturns a DefaultRegister by inputing a bit string, e.g\n\nusing Yao\nregister(bit\"0000\")\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.register-Tuple{AbstractArray{T,2} where T}",
    "page": "Registers",
    "title": "Yao.Registers.register",
    "category": "method",
    "text": "register(raw) -> DefaultRegister\n\nReturns a DefaultRegister from a raw dense array (Vector or Matrix).\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.relax!",
    "page": "Registers",
    "title": "Yao.Registers.relax!",
    "category": "function",
    "text": "relax!(reg::DefaultRegister; nbit::Int=nqubits(reg)) -> DefaultRegister\nrelax!(reg::DefaultRegister, bits::Ints; nbit::Int=nqubits(reg)) -> DefaultRegister\nrelax!(bits::Ints...; nbit::Int=-1) -> Function\n\nInverse transformation of focus, with nbit is the number of active bits of target register.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.relaxedvec-Union{Tuple{DefaultRegister{B,T,MT} where MT<:AbstractArray{T,2} where T}, Tuple{B}} where B",
    "page": "Registers",
    "title": "Yao.Registers.relaxedvec",
    "category": "method",
    "text": "relaxedvec(r::DefaultRegister) -> AbstractArray\n\nReturn a matrix (vector) for B>1 (B=1) as a vector representation of state, with all qubits activated.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.reorder!",
    "page": "Registers",
    "title": "Yao.Registers.reorder!",
    "category": "function",
    "text": "reorder!(reg::AbstractRegister, order) -> AbstractRegister\nreorder!(orders::Int...) -> Function    # currified\n\nReorder the lines of qubits, it also works for array.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.reset!",
    "page": "Registers",
    "title": "Yao.Registers.reset!",
    "category": "function",
    "text": "reset!(reg::AbstractRegister, val::Integer=0) -> AbstractRegister\n\nreset! reg to default value.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.select!-Union{Tuple{B}, Tuple{AbstractRegister{B,T} where T,Any}} where B",
    "page": "Registers",
    "title": "Yao.Registers.select!",
    "category": "method",
    "text": "select!(reg::AbstractRegister, b::Integer) -> AbstractRegister\nselect!(b::Integer) -> Function\n\nselect specific component of qubit, the inplace version, the currified version will return a Function.\n\ne.g. select!(reg, 0b110) will select the subspace with (focused) configuration 110. After selection, the focused qubit space is 0, so you may want call relax! manually.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.select-Union{Tuple{B}, Tuple{DefaultRegister{B,T,MT} where MT<:AbstractArray{T,2} where T,Any}} where B",
    "page": "Registers",
    "title": "Yao.Registers.select",
    "category": "method",
    "text": "select(reg::AbstractRegister, b::Integer) -> AbstractRegister\n\nthe non-inplace version of select! function.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.state",
    "page": "Registers",
    "title": "Yao.Registers.state",
    "category": "function",
    "text": "state(reg) -> AbstractMatrix\n\nget the state of this register. It always return the matrix stored inside.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.statevec-Tuple{DefaultRegister}",
    "page": "Registers",
    "title": "Yao.Registers.statevec",
    "category": "method",
    "text": "statevec(r::DefaultRegister) -> AbstractArray\n\nReturn a state matrix/vector by droping the last dimension of size 1.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.tracedist",
    "page": "Registers",
    "title": "Yao.Registers.tracedist",
    "category": "function",
    "text": "tracedist(reg1::AbstractRegister, reg2::AbstractRegister) -> Vector\ntracedist(reg1::DensityMatrix, reg2::DensityMatrix) -> Vector\n\ntrace distance.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.tracedist-Union{Tuple{B}, Tuple{DensityMatrix{B,T,MT} where MT<:AbstractArray{T,3} where T,DensityMatrix{B,T,MT} where MT<:AbstractArray{T,3} where T}} where B",
    "page": "Registers",
    "title": "Yao.Registers.tracedist",
    "category": "method",
    "text": "tracedist(dm1::DensityMatrix{B}, dm2::DensityMatrix{B}) -> Vector\n\nReturn trace distance between two density matrices.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.uniform_state-Union{Tuple{T}, Tuple{Type{T},Int64}, Tuple{Type{T},Int64,Int64}} where T",
    "page": "Registers",
    "title": "Yao.Registers.uniform_state",
    "category": "method",
    "text": "uniform_state([::Type{T}], n::Int, nbatch::Int=1) -> DefaultRegister\n\nuniform state, the state after applying H gates on |0> state.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.viewbatch",
    "page": "Registers",
    "title": "Yao.Registers.viewbatch",
    "category": "function",
    "text": "viewbatch(r::AbstractRegister, i::Int) -> AbstractRegister{1}\n\nReturn a view of a slice from batch dimension.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.zero_state-Union{Tuple{T}, Tuple{Type{T},Int64}, Tuple{Type{T},Int64,Int64}} where T",
    "page": "Registers",
    "title": "Yao.Registers.zero_state",
    "category": "method",
    "text": "zero_state([::Type{T}], n::Int, nbatch::Int=1) -> DefaultRegister\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.ρ",
    "page": "Registers",
    "title": "Yao.Registers.ρ",
    "category": "function",
    "text": "ρ(register)\n\nReturns the density matrix of this register.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.nactive",
    "page": "Registers",
    "title": "Yao.nactive",
    "category": "function",
    "text": "nactive(x::AbstractRegister) -> Int\n\nReturn the number of active qubits.\n\nnote!!!\n\nOperatiors always apply on active qubits.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.BitStr",
    "page": "Registers",
    "title": "Yao.Registers.BitStr",
    "category": "type",
    "text": "BitStr\n\nString literal for qubits.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Base.join",
    "page": "Registers",
    "title": "Base.join",
    "category": "function",
    "text": "join(reg1::AbstractRegister, reg2::AbstractRegister) -> Register\n\nMerge two registers together with kronecker tensor product.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Base.repeat",
    "page": "Registers",
    "title": "Base.repeat",
    "category": "function",
    "text": "repeat(reg::AbstractRegister{B}, n::Int) -> AbstractRegister\n\nRepeat register in batch dimension for n times.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.shapeorder-Tuple{Tuple{Vararg{T,N}} where T where N,Array{Int64,1}}",
    "page": "Registers",
    "title": "Yao.Registers.shapeorder",
    "category": "method",
    "text": "Get the compact shape and order for permutedims.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Registers-2",
    "page": "Registers",
    "title": "Registers",
    "category": "section",
    "text": "Modules = [Yao.Registers]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/blocks/#",
    "page": "Blocks System",
    "title": "Blocks System",
    "category": "page",
    "text": "CurrentModule = Yao.Blocks"
},

{
    "location": "man/blocks/#Blocks-System-1",
    "page": "Blocks System",
    "title": "Blocks System",
    "category": "section",
    "text": "Blocks are the basic component of a quantum circuit in Yao."
},

{
    "location": "man/blocks/#Block-System-1",
    "page": "Blocks System",
    "title": "Block System",
    "category": "section",
    "text": "The whole framework is consist of a block system. The whole system characterize a quantum circuit into serveral kinds of blocks. The uppermost abstract type for the whole system is AbstractBlock(Image: Block-System)"
},

{
    "location": "man/blocks/#Composite-Blocks-1",
    "page": "Blocks System",
    "title": "Composite Blocks",
    "category": "section",
    "text": ""
},

{
    "location": "man/blocks/#Yao.Blocks.AbstractBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.AbstractBlock",
    "category": "type",
    "text": "AbstractBlock\n\nabstract type that all block will subtype from. N is the number of qubits.\n\nRequired interfaces     * apply! or (and) mat\n\nInterfaces for parametric blocks.\n\n* iparameters\n* setiparameters\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.AbstractContainer",
    "page": "Blocks System",
    "title": "Yao.Blocks.AbstractContainer",
    "category": "type",
    "text": "ContainerBlock{N, T} <: MatrixBlock{N, T}\n\nabstract supertype which container blocks will inherit from.\n\nextended APIs\n\nblock: the block contained by this ContainerBlock\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.AbstractMeasure",
    "page": "Blocks System",
    "title": "Yao.Blocks.AbstractMeasure",
    "category": "type",
    "text": "AbstractMeasure <: AbstractBlock\n\nAbstract block supertype which measurement block will inherit from.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.AbstractScale",
    "page": "Blocks System",
    "title": "Yao.Blocks.AbstractScale",
    "category": "type",
    "text": "AbstractScale{N, T} <: TagBlock{N, T}\n\nBlock for scaling siblings by a factor of X.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.AddBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.AddBlock",
    "category": "type",
    "text": "AddBlock{N, T} <: CompositeBlock{N, T}\n\nAdding multiple blocks into one.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.BPDiff",
    "page": "Blocks System",
    "title": "Yao.Blocks.BPDiff",
    "category": "type",
    "text": "BPDiff{GT, N, T, PT} <: AbstractDiff{GT, N, Complex{T}}\nBPDiff(block, [grad]) -> BPDiff\n\nMark a block as differentiable, here GT, PT is gate type, parameter type.\n\nWarning:     please don\'t use the adjoint after BPDiff! adjoint is reserved for special purpose! (back propagation)\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.BlockTreeIterator",
    "page": "Blocks System",
    "title": "Yao.Blocks.BlockTreeIterator",
    "category": "type",
    "text": "BlockTreeIterator{BT}\n\nIterate through the whole block tree with breadth first search.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.CacheFragment",
    "page": "Blocks System",
    "title": "Yao.Blocks.CacheFragment",
    "category": "type",
    "text": "CacheFragment{BT, K, MT}\n\nA fragment that will be stored for each cached block (of type BT) on a cache server.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.CachedBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.CachedBlock",
    "category": "type",
    "text": "CachedBlock{ST, BT, N, T} <: TagBlock{N, T}\n\nA label type that tags an instance of type BT. It forwards every methods of the block it contains, except mat and apply!, it will cache the matrix form whenever the program has.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ChainBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.ChainBlock",
    "category": "type",
    "text": "ChainBlock{N, T} <: CompositeBlock{N, T}\n\nChainBlock is a basic construct tool to create user defined blocks horizontically. It is a Vector like composite type.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.CompositeBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.CompositeBlock",
    "category": "type",
    "text": "CompositeBlock{N, T} <: MatrixBlock{N, T}\n\nabstract supertype which composite blocks will inherit from.\n\nextended APIs\n\nblocks: get an iteratable of all blocks contained by this CompositeBlock\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Concentrator",
    "page": "Blocks System",
    "title": "Yao.Blocks.Concentrator",
    "category": "type",
    "text": "Concentrator{N, T, BT <: AbstractBlock} <: AbstractContainer{N, T}\n\nconcentrates serveral lines together in the circuit, and expose it to other blocks.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ConstantGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.ConstantGate",
    "category": "type",
    "text": "ConstantGate{N, T} <: PrimitiveBlock{N, T}\n\nAbstract type for constant gates.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ControlBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.ControlBlock",
    "category": "type",
    "text": "ControlBlock{N, BT<:AbstractBlock, C, M, T} <: AbstractContainer{N, T}\n\nN: number of qubits, BT: controlled block type, C: number of control bits, T: type of matrix.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Daggered",
    "page": "Blocks System",
    "title": "Yao.Blocks.Daggered",
    "category": "type",
    "text": "Daggered{N, T, BT} <: TagBlock{N, T}\n\nDaggered(blk::BT)\nDaggered{N, T, BT}(blk)\n\nDaggered Block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.FunctionBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.FunctionBlock",
    "category": "type",
    "text": "FunctionBlock <: AbstractBlock\n\nThis block contains a general function that perform an in-place operation over a register\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.KronBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.KronBlock",
    "category": "type",
    "text": "KronBlock{N, T, MT<:MatrixBlock} <: CompositeBlock{N, T}\n\ncomposite block that combine blocks by kronecker product.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.MathBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.MathBlock",
    "category": "type",
    "text": "MathBlock{L, N, T} <: PrimitiveBlock{N, T}\n\nBlock for arithmatic operations, the operation name can be specified by type parameter L. Note the T parameter represents the kind of view of basis (the input format of func), which should be one of bint, bint_r, bfloat, bfloat_r.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.MatrixBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.MatrixBlock",
    "category": "type",
    "text": "MatrixBlock{N, T} <: AbstractBlock\n\nabstract type that all block with a matrix form will subtype from.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Measure",
    "page": "Blocks System",
    "title": "Yao.Blocks.Measure",
    "category": "type",
    "text": "Measure <: AbstractMeasure\nMeasure() -> Measure\n\nMeasure block, collapse a state and store measured value, e.g.\n\nExamples\n\njulia> m = Measure();\n\njulia> reg = product_state(4, 7)\nDefaultRegister{1, Complex{Float64}}\n    active qubits: 4/4\n\njulia> reg |> m\nDefaultRegister{1, Complex{Float64}}\n    active qubits: 4/4\n\njulia> m.result\n1-element Array{Int64,1}:\n 7\n\nNote: Measure returns a vector here, the length corresponds to batch dimension of registers.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.MeasureAndRemove",
    "page": "Blocks System",
    "title": "Yao.Blocks.MeasureAndRemove",
    "category": "type",
    "text": "MeasureAndRemove <: AbstractMeasure\nMeasureAndRemove() -> MeasureAndRemove\n\nMeasure and remove block, remove measured qubits and store measured value.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.MeasureAndReset",
    "page": "Blocks System",
    "title": "Yao.Blocks.MeasureAndReset",
    "category": "type",
    "text": "MeasureAndReset <: AbstractMeasure\nMeasureAndReset([val=0]) -> MeasureAndReset\n\nMeasure and reset block, reset measured qubits to val and store measured value.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.PhaseGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.PhaseGate",
    "category": "type",
    "text": "PhiGate\n\nGlobal phase gate.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.PrimitiveBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.PrimitiveBlock",
    "category": "type",
    "text": "PrimitiveBlock{N, T} <: MatrixBlock{N, T}\n\nabstract type that all primitive block will subtype from. A primitive block is a concrete block who can not be decomposed into other blocks. All composite block can be decomposed into several primitive blocks.\n\nNOTE: subtype for primitive block with parameter should implement hash and == method to enable key value cache.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.PutBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.PutBlock",
    "category": "type",
    "text": "PutBlock{N, C, GT, T} <: AbstractContainer{N, T}\n\nput a block on given addrs.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.QDiff",
    "page": "Blocks System",
    "title": "Yao.Blocks.QDiff",
    "category": "type",
    "text": "QDiff{GT, N, T} <: AbstractDiff{GT, N, Complex{T}}\nQDiff(block) -> QDiff\n\nMark a block as quantum differentiable.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ReflectBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.ReflectBlock",
    "category": "type",
    "text": "ReflectBlock{N, T} <: PrimitiveBlock{N, T}\n\nHouseholder reflection with respect to some target state, psirangle = 2sranglelangle s-1.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.RepeatedBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.RepeatedBlock",
    "category": "type",
    "text": "RepeatedBlock{N, C, GT, T} <: AbstractContainer{N, T}\n\nrepeat the same block on given addrs.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Roller",
    "page": "Blocks System",
    "title": "Yao.Blocks.Roller",
    "category": "type",
    "text": "Roller{N, T, BT} <: CompositeBlock{N, T}\n\nmap a block type to all lines and use a rolling method to evaluate them.\n\nTODO\n\nfill identity like KronBlock -> To interface.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.RotationGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.RotationGate",
    "category": "type",
    "text": "RotationGate{N, T, GT <: MatrixBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}\n\nRotationGate, with GT both hermitian and isreflexive.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Scale",
    "page": "Blocks System",
    "title": "Yao.Blocks.Scale",
    "category": "type",
    "text": "Scale{BT, FT, N, T} <: AbstractScale{N, T}\n\nScale(block, factor) -> Scale\n\nScale Block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Sequential",
    "page": "Blocks System",
    "title": "Yao.Blocks.Sequential",
    "category": "type",
    "text": "Sequential <: AbstractBlock\n\nsequencial structure that looser than a chain, it does not require qubit consistency and does not have mat method.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ShiftGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.ShiftGate",
    "category": "type",
    "text": "ShiftGate <: PrimitiveBlock\n\nPhase shift gate.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.StaticScale",
    "page": "Blocks System",
    "title": "Yao.Blocks.StaticScale",
    "category": "type",
    "text": "StaticScale{X, BT, N, T} <: AbstractScale{N, T}\n\nStaticScale{X}(blk::MatrixBlock)\nStaticScale{X, N, T, BT}(blk::MatrixBlock)\n\nScale Block, by a static factor of X, notice X is static!\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.TagBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.TagBlock",
    "category": "type",
    "text": "TagBlock{N, T} <: AbstractContainer{N, T}\n\nTagBlock is a special kind of Container, it is a size keeper.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.TimeEvolution",
    "page": "Blocks System",
    "title": "Yao.Blocks.TimeEvolution",
    "category": "type",
    "text": "TimeEvolution{N, TT, GT} <: PrimitiveBlock{N, ComplexF64}\n\nTimeEvolution(H::GT, t::TT; tol::Real=1e-7) -> TimeEvolution\n\nTimeEvolution, where GT is block type. input matrix should be hermitian.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.apply!",
    "page": "Blocks System",
    "title": "Yao.Blocks.apply!",
    "category": "function",
    "text": "apply!(reg, block, [signal])\n\napply a block to a register reg with or without a cache signal.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.applymatrix-Tuple{AbstractBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.applymatrix",
    "category": "method",
    "text": "applymatrix(g::AbstractBlock) -> Matrix\n\nTransform the apply! function of specific block to dense matrix.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.backward!-Tuple{AbstractRegister,MatrixBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.backward!",
    "category": "method",
    "text": "backward!(δ::AbstractRegister, circuit::MatrixBlock) -> AbstractRegister\n\nback propagate and calculate the gradient ∂f/∂θ = 2Re(∂f/∂ψ⋅∂ψ/∂θ), given ∂f/∂ψ.\n\nNote: Here, the input circuit should be a matrix block, otherwise the back propagate may not apply (like Measure operations).\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.block",
    "page": "Blocks System",
    "title": "Yao.Blocks.block",
    "category": "function",
    "text": "block(container::AbstractContainer) -> AbstractBlock\n\nget the contained block (i.e. subblock) of a container.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.blockfilter-Tuple{Any,AbstractBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.blockfilter",
    "category": "method",
    "text": "blockfilter(func, blk::AbstractBlock) -> Vector{AbstractBlock}\nblockfilter!(func, rgs::Vector, blk::AbstractBlock) -> Vector{AbstractBlock}\n\ntree wise filtering for blocks.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.chblock",
    "page": "Blocks System",
    "title": "Yao.Blocks.chblock",
    "category": "function",
    "text": "chblock(block, blk)\n\nchange the block of a container.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.chfactor",
    "page": "Blocks System",
    "title": "Yao.Blocks.chfactor",
    "category": "function",
    "text": "chfactor(blk::AbstractScale) -> AbstractScale\n\nchange scaling factor of blk.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.chsubblocks-Tuple{AbstractBlock,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.chsubblocks",
    "category": "method",
    "text": "chsubblocks(pb::AbstractBlock, blks) -> AbstractBlock\n\nChange subblocks of target block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.dispatch!!-Tuple{AbstractBlock,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.dispatch!!",
    "category": "method",
    "text": "dispatch!!([func::Function], block::AbstractBlock, params) -> AbstractBlock\n\nSimilar to dispatch!, but will pop! out params inplace, it can not more efficient.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.dispatch!-Tuple{AbstractBlock,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.dispatch!",
    "category": "method",
    "text": "dispatch!([func::Function], block::AbstractBlock, params) -> AbstractBlock\ndispatch!([func::Function], block::AbstractBlock, :random) -> AbstractBlock\ndispatch!([func::Function], block::AbstractBlock, :zero) -> AbstractBlock\n\ndispatch! parameters into this circuit, here params is an iterable.\n\nIf instead of iterable, a symbol :random or :zero is provided, random numbers (its behavior is specified by setiparameters!) or 0s will be broadcasted into circuits.\n\nusing dispatch!! is more efficient, but will pop! out all params inplace.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.expect",
    "page": "Blocks System",
    "title": "Yao.Blocks.expect",
    "category": "function",
    "text": "expect(op::AbstractBlock, reg::AbstractRegister{B}) -> Vector\nexpect(op::AbstractBlock, dm::DensityMatrix{B}) -> Vector\n\nexpectation value of an operator.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.factor",
    "page": "Blocks System",
    "title": "Yao.Blocks.factor",
    "category": "function",
    "text": "factor(blk::AbstractScale) -> Number\n\nget scaling factor of blk.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.generator-Tuple{RotationGate}",
    "page": "Blocks System",
    "title": "Yao.Blocks.generator",
    "category": "method",
    "text": "generator(rot::Rotor) -> MatrixBlock\n\nReturn the generator of rotation block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.gradient",
    "page": "Blocks System",
    "title": "Yao.Blocks.gradient",
    "category": "function",
    "text": "gradient(circuit::AbstractBlock, mode::Symbol=:ANY) -> Vector\n\ncollect all gradients in a circuit, mode can be :BP/:QC/:ANY, they will collect grad from BPDiff/QDiff/AbstractDiff respectively.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.iparameter_type-Tuple{AbstractBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.iparameter_type",
    "category": "method",
    "text": "iparameter_type(block::AbstractBlock) -> Type\n\nelement type of iparameters(block).\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.iparameters",
    "page": "Blocks System",
    "title": "Yao.Blocks.iparameters",
    "category": "function",
    "text": "iparameters(block) -> Vector\n\nReturns a list of all intrinsic (not from sublocks) parameters in block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.mat",
    "page": "Blocks System",
    "title": "Yao.Blocks.mat",
    "category": "function",
    "text": "mat(block) -> Matrix\n\nReturns the matrix form of this block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.niparameters",
    "page": "Blocks System",
    "title": "Yao.Blocks.niparameters",
    "category": "function",
    "text": "niparameters(x) -> Integer\n\nReturns the number of parameters of x.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.nparameters-Tuple{AbstractBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.nparameters",
    "category": "method",
    "text": "nparameters(c::AbstractBlock) -> Int\n\nnumber of parameters, including parameters in sublocks.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.parameter_type",
    "page": "Blocks System",
    "title": "Yao.Blocks.parameter_type",
    "category": "function",
    "text": "parameter_type(block) -> Type\n\nthe type of iparameters.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.parameters",
    "page": "Blocks System",
    "title": "Yao.Blocks.parameters",
    "category": "function",
    "text": "parameters(c::AbstractBlock, [output]) -> Vector\n\nget all parameters including sublocks.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.setiparameters!",
    "page": "Blocks System",
    "title": "Yao.Blocks.setiparameters!",
    "category": "function",
    "text": "setparameters!([elementwisefunction], r::AbstractBlock, params::Number...) -> AbstractBlock\nsetparameters!([elementwisefunction], r::AbstractBlock, :random) -> AbstractBlock\nsetparameters!([elementwisefunction], r::AbstractBlock, :zero) -> AbstractBlock\n\nset intrinsics parameter for block, input params can be numbers or :random or :zero.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.subblocks",
    "page": "Blocks System",
    "title": "Yao.Blocks.subblocks",
    "category": "function",
    "text": "subblocks(blk::AbstractBlock) -> Tuple\n\nreturn a tuple of all sub-blocks in this block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.traverse-Tuple{Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.traverse",
    "category": "method",
    "text": "traverse(blk; algorithm=:DFS) -> BlockTreeIterator\n\nReturns an iterator that traverse through the block tree.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.usedbits-Union{Tuple{MatrixBlock{N,T} where T}, Tuple{N}} where N",
    "page": "Blocks System",
    "title": "Yao.Blocks.usedbits",
    "category": "method",
    "text": "addrs(block::AbstractBlock) -> Vector{Int}\n\nOccupied addresses (include control bits and bits occupied by blocks), fall back to all bits if this method is not provided.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Intrinsics.isreflexive",
    "page": "Blocks System",
    "title": "Yao.Intrinsics.isreflexive",
    "category": "function",
    "text": "isreflexive(x) -> Bool\n\nTest whether this operator is reflexive.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Intrinsics.isunitary",
    "page": "Blocks System",
    "title": "Yao.Intrinsics.isunitary",
    "category": "function",
    "text": "isunitary(x) -> Bool\n\nTest whether this operator is unitary.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Registers.datatype-Union{Tuple{MatrixBlock{N,T}}, Tuple{T}, Tuple{N}} where T where N",
    "page": "Blocks System",
    "title": "Yao.Registers.datatype",
    "category": "method",
    "text": "datatype(x) -> DataType\n\nReturns the data type of x.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.nqubits-Union{Tuple{Type{MT}}, Tuple{MT}, Tuple{N}} where MT<:(MatrixBlock{N,T} where T) where N",
    "page": "Blocks System",
    "title": "Yao.nqubits",
    "category": "method",
    "text": "nqubits(::Type{MT}) -> Int\nnqubits(::MatrixBlock) -> Int\n\nReturn the number of qubits of a MatrixBlock.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Base.collect-Union{Tuple{BT}, Tuple{AbstractBlock,Type{BT}}} where BT<:AbstractBlock",
    "page": "Blocks System",
    "title": "Base.collect",
    "category": "method",
    "text": "collect(circuit::AbstractBlock, ::Type{BT}) where BT<:AbstractBlock\n\ncollect blocks of type BT in the block tree with circuit as root.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks._allmatblock-Tuple{Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks._allmatblock",
    "category": "method",
    "text": "all blocks are matrix blocks\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks._blockpromote-Tuple{Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks._blockpromote",
    "category": "method",
    "text": "promote types of blocks\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.cache_key",
    "page": "Blocks System",
    "title": "Yao.Blocks.cache_key",
    "category": "function",
    "text": "cache_key(block)\n\nReturns the key that identify the matrix cache of this block. By default, we use the returns of parameters as its key.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.cache_type-Tuple{Type{#s90} where #s90<:MatrixBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.cache_type",
    "category": "method",
    "text": "cache_type(::Type) -> DataType\n\nA type trait that defines the element type that a CacheFragment will use.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.istraitkeeper",
    "page": "Blocks System",
    "title": "Yao.Blocks.istraitkeeper",
    "category": "function",
    "text": "istraitkeeper(block) -> Bool\n\nchange the block of a container.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.print_block-Tuple{IO,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.print_block",
    "category": "method",
    "text": "print_block(io, block)\n\ndefine the style to print this block\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.render_params-Tuple{AbstractBlock,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.render_params",
    "category": "method",
    "text": "render_params(r::AbstractBlock, raw_parameters) -> Iterable\n\nMore elegant way of rendering parameters for symbols.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ConstGateTools.@const_gate-Tuple{Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.ConstGateTools.@const_gate",
    "category": "macro",
    "text": "@const_gate NAME = MAT_EXPR\n@const_gate NAME::Type = MAT_EXPR\n@const_Gate NAME::Type\n\nThis macro simplify the definition of a constant gate. It will automatically bind the matrix form to a constant which will reduce memory allocation in the runtime.\n\n@const_gate X = ComplexF64[0 1;1 0]\n\nor\n\n@const_gate X::ComplexF64 = [0 1;1 0]\n\nYou can bind new element types by simply re-declare with a type annotation.\n\n@const_gate X::ComplexF32\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Blocks-1",
    "page": "Blocks System",
    "title": "Blocks",
    "category": "section",
    "text": "Modules = [Yao.Blocks, Yao.Blocks.ConstGateTools]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/intrinsics/#",
    "page": "Intrinsics",
    "title": "Intrinsics",
    "category": "page",
    "text": ""
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.AddressConflictError",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.AddressConflictError",
    "category": "type",
    "text": "AddressConflictError <: Exception\n\nAddress conflict error in Block Construction.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.IterControl",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.IterControl",
    "category": "type",
    "text": "IterControl{N, C}\n\nN is the size of hilbert space, C is the number of shifts.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.QubitMismatchError",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.QubitMismatchError",
    "category": "type",
    "text": "QubitMismatchError <: Exception\n\nQubit number mismatch error when applying a Block to a Register or concatenating Blocks.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#LinearAlgebra.ishermitian-Tuple{Any}",
    "page": "Intrinsics",
    "title": "LinearAlgebra.ishermitian",
    "category": "method",
    "text": "ishermitian(op) -> Bool\n\ncheck if this operator is hermitian.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.baddrs-Tuple{Integer}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.baddrs",
    "category": "method",
    "text": "baddrs(b::Integer) -> Vector\n\nget the locations of nonzeros bits, i.e. the inverse operation of bmask.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.basis-Tuple{Union{Int64, AbstractArray}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.basis",
    "category": "method",
    "text": "basis([IntType], num_bit::Int) -> UnitRange{IntType}\nbasis([IntType], state::AbstractArray) -> UnitRange{IntType}\n\nReturns the UnitRange for basis in Hilbert Space of num_bit qubits. If an array is supplied, it will return a basis having the same size with the first diemension of array.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.batch_normalize",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.batch_normalize",
    "category": "function",
    "text": "batch_normalize\n\nnormalize a batch of vector.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.batch_normalize!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.batch_normalize!",
    "category": "function",
    "text": "batch_normalize!(matrix)\n\nnormalize a batch of vector.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bdistance-Union{Tuple{Ti}, Tuple{Ti,Ti}} where Ti<:Integer",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bdistance",
    "category": "method",
    "text": "bdistance(i::Integer, j::Integer) -> Int\n\nReturn number of different bits.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bfloat-Tuple{Integer}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bfloat",
    "category": "method",
    "text": "bfloat(b::Integer; nbit::Int=bit_length(b)) -> Float64\n\nfloat view, with big end qubit 1.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bfloat_r-Tuple{Integer}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bfloat_r",
    "category": "method",
    "text": "bfloat_r(b::Integer; nbit::Int) -> Float64\n\nfloat view, with bits read in inverse order.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bint-Tuple{Integer}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bint",
    "category": "method",
    "text": "bint(b; nbit=nothing) -> Int\n\ninteger view, with little end qubit 1.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bint_r-Tuple{Integer}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bint_r",
    "category": "method",
    "text": "bint_r(b; nbit::Int) -> Integer\n\ninteger read in inverse order.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bit_length-Tuple{Integer}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bit_length",
    "category": "method",
    "text": "bit_length(x::Integer) -> Int\n\nReturn the number of bits required to represent input integer x.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bitarray-Union{Tuple{T}, Tuple{Array{T,1},Int64}} where T<:Number",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bitarray",
    "category": "method",
    "text": "bitarray(v::Vector, [num_bit::Int]) -> BitArray\nbitarray(v::Int, num_bit::Int) -> BitArray\nbitarray(num_bit::Int) -> Function\n\nConstruct BitArray from an integer vector, if num_bit not supplied, it is 64. If an integer is supplied, it returns a function mapping a Vector/Int to bitarray.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bmask",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bmask",
    "category": "function",
    "text": "bmask([IntType], ibit::Int...) -> IntType\nbmask([IntType], bits::UnitRange{Int}) ->IntType\n\nReturn an integer with specific position masked, which is offten used as a mask for binary operations.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.breflect",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.breflect",
    "category": "function",
    "text": "breflect(num_bit::Int, b::Integer[, masks::Vector{Integer}]) -> Integer\n\nReturn left-right reflected integer.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bsizeof-Tuple{Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bsizeof",
    "category": "method",
    "text": "bsizeof(x) -> Int\n\nReturn the size of object, in number of bit.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.controldo-Union{Tuple{C}, Tuple{N}, Tuple{Function,IterControl{N,C}}} where C where N",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.controldo",
    "category": "method",
    "text": "controldo(func::Function, ic::IterControl{N, C})\n\nFaster than for i in ic ... end.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.controller-Tuple{Union{UnitRange{Int64}, Int64, Array{Int64,1}, Tuple{Vararg{Int64,#s16}} where #s16},Union{UnitRange{Int64}, Int64, Array{Int64,1}, Tuple{Vararg{Int64,#s16}} where #s16}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.controller",
    "category": "method",
    "text": "controller(cbits, cvals) -> Function\n\nReturn a function that test whether a basis at cbits takes specific value cvals.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.cunapply!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.cunapply!",
    "category": "function",
    "text": "control-unitary\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.cunmat",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.cunmat",
    "category": "function",
    "text": "cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::AbstractMatrix, locs::NTuple{M, Int}) where {C, M} -> AbstractMatrix\n\ncontrol-unitary matrix\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.fidelity_mix-Tuple{Array{T,2} where T,Array{T,2} where T}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.fidelity_mix",
    "category": "method",
    "text": "fidelity_mix(m1::Matrix, m2::Matrix)\n\nFidelity for mixed states.\n\nReference:     http://iopscience.iop.org/article/10.1088/1367-2630/aa6a4b/meta\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.fidelity_pure-Tuple{Array{T,1} where T,Array{T,1} where T}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.fidelity_pure",
    "category": "method",
    "text": "fidelity for pure states.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.flip-Union{Tuple{Ti}, Tuple{Ti,Ti}} where Ti<:Integer",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.flip",
    "category": "method",
    "text": "flip(index::Integer, mask::Integer) -> Integer\n\nReturn an Integer with bits at masked position flipped.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.general_c1_gates-Union{Tuple{Tp}, Tuple{Tg}, Tuple{Int64,Tp,Int64,Array{Tg,1},Array{Int64,1}}} where Tp<:(AbstractArray{T,2} where T) where Tg<:(AbstractArray{T,2} where T)",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.general_c1_gates",
    "category": "method",
    "text": "general_c1_gates(num_bit::Int, projector::AbstractMatrix, cbit::Int, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix\n\ngeneral (low performance) construction method for control gate on different lines.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.general_controlled_gates-Tuple{Int64,Array{#s12,1} where #s12<:(AbstractArray{T,2} where T),Array{Int64,1},Array{#s16,1} where #s16<:(AbstractArray{T,2} where T),Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.general_controlled_gates",
    "category": "method",
    "text": "general_controlled_gates(num_bit::Int, projectors::Vector{Tp}, cbits::Vector{Int}, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix\n\nReturn general multi-controlled gates in hilbert space of num_bit qubits,\n\nprojectors are often chosen as P0 and P1 for inverse-Control and Control at specific position.\ncbits should have the same length as projectors, specifing the controling positions.\ngates are a list of controlled single qubit gates.\nlocs should have the same length as gates, specifing the gates positions.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.getcol-Tuple{Union{SSparseMatrixCSC, SparseMatrixCSC},Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.getcol",
    "category": "method",
    "text": "getcol(csc::SDparseMatrixCSC, icol::Int) -> (View, View)\n\nget specific col of a CSC matrix, returns a slice of (rowval, nzval)\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.hilbertkron-Union{Tuple{T}, Tuple{Int64,Array{T,1},Array{Int64,1}}} where T<:(AbstractArray{T,2} where T)",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.hilbertkron",
    "category": "method",
    "text": "hilbertkron(num_bit::Int, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix\n\nReturn general kronecher product form of gates in Hilbert space of num_bit qubits.\n\ngates are a list of matrices.\nstart_locs should have the same length as gates, specifing the gates starting positions.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.hypercubic-Tuple{Array}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.hypercubic",
    "category": "method",
    "text": "hypercubic(A::Union{Array, DefaultRegister}) -> Array\n\nget the hypercubic representation for an array or a regiseter.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.indices_with-Tuple{Int64,Array{Int64,1},Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.indices_with",
    "category": "method",
    "text": "indices_with(num_bit::Int, poss::Vector{Int}, vals::Vector{Int}) -> Vector{Int}\n\nReturn indices with specific positions poss with value vals in a hilbert space of num_bit qubits.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.iscommute-Tuple",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.iscommute",
    "category": "method",
    "text": "iscommute(ops...) -> Bool\n\ncheck if operators are commute.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.isreflexive-Tuple{Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.isreflexive",
    "category": "method",
    "text": "isreflexive(op) -> Bool\n\ncheck if this operator is reflexive.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.isunitary-Tuple{Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.isunitary",
    "category": "method",
    "text": "isunitary(op) -> Bool\n\ncheck if this operator is a unitary operator.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.itercontrol-Tuple{Int64,Array{Int64,1},Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.itercontrol",
    "category": "method",
    "text": "itercontrol(num_bit::Int, poss::Vector{Int}, vals::Vector{Int}) -> IterControl\n\nReturn the iterator for basis with poss controlled to values vals, with the total number of bits num_bit.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.linop2dense-Tuple{Function,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.linop2dense",
    "category": "method",
    "text": "linop2dense(applyfunc!::Function, num_bit::Int) -> Matrix\n\nget the dense matrix representation given matrix*matrix function.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.log2i",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.log2i",
    "category": "function",
    "text": "log2i(x::Integer) -> Integer\n\nReturn log2(x), this integer version of log2 is fast but only valid for number equal to 2^n.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.matvec",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.matvec",
    "category": "function",
    "text": "matvec(x::VecOrMat) -> MatOrVec\n\nReturn vector if a matrix is a column vector, else untouched.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.mulcol!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.mulcol!",
    "category": "function",
    "text": "mulcol!(v::AbstractVector, i::Int, f) -> VecOrMat\n\nmultiply col i of v by f inplace.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.mulrow!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.mulrow!",
    "category": "function",
    "text": "mulrow!(v::AbstractVector, i::Int, f) -> VecOrMat\n\nmultiply row i of v by f inplace.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.neg-Union{Tuple{Ti}, Tuple{Ti,Int64}} where Ti<:Integer",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.neg",
    "category": "method",
    "text": "neg(index::Integer, num_bit::Int) -> Integer\n\nReturn an integer with all bits flipped (with total number of bit num_bit).\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.onehotvec-Union{Tuple{T}, Tuple{Type{T},Int64,Integer}} where T",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.onehotvec",
    "category": "method",
    "text": "onehotvec(::Type{T}, num_bit::Int, x::Integer) -> Vector{T}\n\none-hot wave vector.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.packbits-Tuple{AbstractArray{T,1} where T}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.packbits",
    "category": "method",
    "text": "packbits(arr::AbstractArray) -> AbstractArray\n\npack bits to integers, usually take a BitArray as input.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.rand_hermitian-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.rand_hermitian",
    "category": "method",
    "text": "rand_hermitian(N::Int) -> Matrix\n\nRandom hermitian matrix.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.rand_unitary-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.rand_unitary",
    "category": "method",
    "text": "rand_unitary(N::Int) -> Matrix\n\nRandom unitary matrix.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.reordered_basis-Tuple{Int64,Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.reordered_basis",
    "category": "method",
    "text": "Reordered Basis\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.setbit-Union{Tuple{Ti}, Tuple{Ti,Ti}} where Ti<:Integer",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.setbit",
    "category": "method",
    "text": "setbit(index::Integer, mask::Integer) -> Integer\n\nset the bit at masked position to 1.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.setcol!-Tuple{SparseArrays.SparseMatrixCSC,Int64,AbstractArray{T,1} where T,Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.setcol!",
    "category": "method",
    "text": "setcol!(csc::SparseMatrixCSC, icol::Int, rowval::AbstractVector, nzval) -> SparseMatrixCSC\n\nset specific col of a CSC matrix\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.swapbits-Union{Tuple{Ti}, Tuple{Ti,Ti}} where Ti<:Integer",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.swapbits",
    "category": "method",
    "text": "swapbits(num::Integer, mask12::Integer) -> Integer\n\nReturn an integer with bits at i and j flipped.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.swapcols!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.swapcols!",
    "category": "function",
    "text": "swapcols!(v::VecOrMat, i::Int, j::Int[, f1, f2]) -> VecOrMat\n\nswap col i and col j of v inplace, with f1, f2 factors applied on i and j (before swap).\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.swaprows!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.swaprows!",
    "category": "function",
    "text": "swaprows!(v::VecOrMat, i::Int, j::Int[, f1, f2]) -> VecOrMat\n\nswap row i and row j of v inplace, with f1, f2 factors applied on i and j (before swap).\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.takebit-Union{Tuple{Ti}, Tuple{Ti,Int64}} where Ti<:Integer",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.takebit",
    "category": "method",
    "text": "takebit(index::Integer, bits::Int...) -> Int\n\nReturn a bit(s) at specific position.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.testall-Union{Tuple{Ti}, Tuple{Ti,Ti}} where Ti<:Integer",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.testall",
    "category": "method",
    "text": "testall(index::Integer, mask::Integer) -> Bool\n\nReturn true if all masked position of index is 1.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.testany-Union{Tuple{Ti}, Tuple{Ti,Ti}} where Ti<:Integer",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.testany",
    "category": "method",
    "text": "testany(index::Integer, mask::Integer) -> Bool\n\nReturn true if any masked position of index is 1.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.testval-Union{Tuple{Ti}, Tuple{Ti,Ti,Ti}} where Ti<:Integer",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.testval",
    "category": "method",
    "text": "testval(index::Integer, mask::Integer, onemask::Integer) -> Bool\n\nReturn true if values at positions masked by mask with value 1 at positions masked by onemask and 0 otherwise.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.u1rows!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.u1rows!",
    "category": "function",
    "text": "u1rows!(state::VecOrMat, i::Int, j::Int, a, b, c, d) -> VecOrMat\n\napply u1 on row i and row j of state inplace.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.unmat-Tuple{Int64,AbstractArray{T,2} where T,Tuple{Vararg{T,N}} where T where N}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.unmat",
    "category": "method",
    "text": "unmat(nbit::Int, U::AbstractMatrix, locs::NTuple) -> AbstractMatrix\n\nReturns the matrix representation of putting matrix at locs.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Base.sort-Tuple{Tuple}",
    "page": "Intrinsics",
    "title": "Base.sort",
    "category": "method",
    "text": "sort(t::Tuple; lt=isless, by=identity, rev::Bool=false) -> ::Tuple\n\nSorts the tuple t.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Base.sortperm-Tuple{Tuple}",
    "page": "Intrinsics",
    "title": "Base.sortperm",
    "category": "method",
    "text": "sortperm(t::Tuple; lt=isless, by=identity, rev::Bool=false) -> ::Tuple\n\nComputes a tuple that contains the permutation required to sort t.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.autostatic-Tuple{Union{AbstractArray{T,1}, AbstractArray{T,2}} where T}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.autostatic",
    "category": "method",
    "text": "turn a vector/matrix to static vector/matrix (only if its length <= 256).\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.u1ij!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.u1ij!",
    "category": "function",
    "text": "u1ij!(target, i, j, a, b, c, d)\n\nsingle u1 matrix into a target matrix.\n\nNote: For coo, we take a additional parameter     * ptr: starting position to store new data.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.nactive-Tuple{AbstractArray}",
    "page": "Intrinsics",
    "title": "Yao.nactive",
    "category": "method",
    "text": "nactive(m::AbstractArray) -> Int\n\nReturns the log-size of its first dimension.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Intrinsics-1",
    "page": "Intrinsics",
    "title": "Intrinsics",
    "category": "section",
    "text": "Modules = [Yao.Intrinsics]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/boost/#",
    "page": "Boost",
    "title": "Boost",
    "category": "page",
    "text": ""
},

{
    "location": "man/boost/#Yao.Boost.controlled_U1",
    "page": "Boost",
    "title": "Yao.Boost.controlled_U1",
    "category": "function",
    "text": "controlled_U1(num_bit::Int, gate::AbstractMatrix, cbits::Vector{Int}, b2::Int) -> AbstractMatrix\n\nReturn general multi-controlled single qubit gate in hilbert space of num_bit qubits.\n\ncbits specify the controling positions.\nb2 is the controlled position.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.cxgate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Any,Any,Union{UnitRange{IT}, Array{IT,1}, Tuple{Vararg{IT,#s16}} where #s16, IT} where IT<:Integer}} where MT<:Number",
    "page": "Boost",
    "title": "Yao.Boost.cxgate",
    "category": "method",
    "text": "cxgate(::Type{MT}, num_bit::Int, b1::Ints, b2::Ints) -> PermMatrix\n\nSingle (Multiple) Controlled-X Gate on single (multiple) bits.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.cygate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Any,Any,Int64}} where MT<:Complex",
    "page": "Boost",
    "title": "Yao.Boost.cygate",
    "category": "method",
    "text": "cygate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) -> PermMatrix\n\nSingle Controlled-Y Gate on single bit.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.xgate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Union{UnitRange{IT}, Array{IT,1}, Tuple{Vararg{IT,#s16}} where #s16, IT} where IT<:Integer}} where MT<:Number",
    "page": "Boost",
    "title": "Yao.Boost.xgate",
    "category": "method",
    "text": "xgate(::Type{MT}, num_bit::Int, bits::Ints) -> PermMatrix\n\nX Gate on multiple bits.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.ygate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Union{UnitRange{IT}, Array{IT,1}, Tuple{Vararg{IT,#s16}} where #s16, IT} where IT<:Integer}} where MT<:Complex",
    "page": "Boost",
    "title": "Yao.Boost.ygate",
    "category": "method",
    "text": "ygate(::Type{MT}, num_bit::Int, bits::Ints) -> PermMatrix\n\nY Gate on multiple bits.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.zgate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Union{UnitRange{IT}, Array{IT,1}, Tuple{Vararg{IT,#s16}} where #s16, IT} where IT<:Integer}} where MT<:Number",
    "page": "Boost",
    "title": "Yao.Boost.zgate",
    "category": "method",
    "text": "zgate(::Type{MT}, num_bit::Int, bits::Ints) -> Diagonal\n\nZ Gate on multiple bits.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Boost-1",
    "page": "Boost",
    "title": "Boost",
    "category": "section",
    "text": "Boost is an optimization module that offers many functions for optimization.Modules = [Yao.Boost]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "dev/extending-blocks/#",
    "page": "Extending Blocks",
    "title": "Extending Blocks",
    "category": "page",
    "text": "CurrentModule = Yao.Blocks"
},

{
    "location": "dev/extending-blocks/#Extending-Blocks-1",
    "page": "Extending Blocks",
    "title": "Extending Blocks",
    "category": "section",
    "text": ""
},

{
    "location": "dev/extending-blocks/#Extending-constant-gate-1",
    "page": "Extending Blocks",
    "title": "Extending constant gate",
    "category": "section",
    "text": "We prepared a macro for you about constant gates like X, Y, Z.Simply use @const_gate."
},

{
    "location": "dev/extending-blocks/#Extending-Primitive-Block-with-parameters-1",
    "page": "Extending Blocks",
    "title": "Extending Primitive Block with parameters",
    "category": "section",
    "text": "First, define your own block type by subtyping PrimitiveBlock. And import methods you will need to overloadusing Yao, Yao.Blocks\nimport Yao.Blocks: mat, dispatch!, parameters # this is the mimimal methods you will need to overload\n\nmutable struct NewPrimitive{T} <: PrimitiveBlock{1, T}\n   theta::T\nendSecond define its matrix form.mat(g::NewPrimitive{T}) where T = Complex{T}[sin(g.theta) 0; cos(g.theta) 0]Yao will use this matrix to do the simulation by default. However, if you know how to directly apply your block to a quantum register, you can also overload apply! to make your simulation become more efficient. But this is not required.import Yao.Blocks: apply!\napply!(r::AbstractRegister, x::NewPrimitive) = # some efficient way to simulate this blockThird If your block contains parameters, declare which member it is with dispatch! and how to get them by parametersdispatch!(g::NewPrimitive, theta) = (g.theta = theta; g)\nparameters(x::NewPrimitive) = x.thetaThe prototype of dispatch! is simple, just directly write the parameters as your function argument. e.gmutable struct MultiParam{N, T} <: PrimitiveBlock{N, Complex{T}}\n  theta::T\n  phi::T\nendjust write:dispatch!(x::MultiParam, theta, phi) = (x.theta = theta; x.phi = phi; x)or maybe your block contains a vector of parameters:mutable struct VecParam{N, T} <: PrimitiveBlock{N, T}\n  params::Vector{T}\nendjust write:dispatch!(x::VecParam, params) = (x.params .= params; x)be careful, the assignment should be in-placed with .= rather than =.If the number of parameters in your new block is fixed, we recommend you to declare this with a type trait nparameters:import Yao.Blocks: nparameters\nnparameters(::Type{<:NewPrimitive}) = 1But it is OK if you do not define this trait, Yao will find out how many parameters you have dynamically.Fourth If you want to enable cache of this new block, you have to define your own cachekey. usually just use your parameters as the key if you want to cache the matrix form of different parameters, which will accelerate your simulation with a cost of larger memory allocation. You can simply define it with [`cachekey`](@ref)import Yao.Blocks: cache_key\ncache_key(x::NewPrimitive) = x.theta"
},

{
    "location": "dev/extending-blocks/#Extending-Composite-Blocks-1",
    "page": "Extending Blocks",
    "title": "Extending Composite Blocks",
    "category": "section",
    "text": "Composite blocks are blocks that are able to contain other blocks. To define a new composite block you only need to define your new type as a subtype of CompositeBlock, and define a new method called subblocks which will provide an iterator that iterates the blocks contained by this composite block."
},

{
    "location": "dev/extending-blocks/#Custom-Pretty-Printing-1",
    "page": "Extending Blocks",
    "title": "Custom Pretty Printing",
    "category": "section",
    "text": "The whole quantum circuit is represented as a tree in the block system. Therefore, we print a block as a tree. To define your own syntax to print, simply overloads the print_block method. Then it will appears in the block tree syntax automatically.print_block(io::IO, block::MyBlockType)"
},

{
    "location": "dev/extending-blocks/#Adding-Operator-Traits-to-Your-Blocks-1",
    "page": "Extending Blocks",
    "title": "Adding Operator Traits to Your Blocks",
    "category": "section",
    "text": "A gate G can have following traitsisunitary - G^dagger G = mathbb1\nisreflexive - GG = mathbb1\nishermitian - G^dagger = GIf G is a MatrixBlock, these traits can fall back to using mat method albiet not efficient. If you can know these traits of a gate clearly, you can define them by hand to improve performance.These traits are useful, e.g. a RotationGate defines an SU(2) rotation, which requires its generator both hermitian a reflexive so that R_G(theta) = cosfractheta2 - isinfractheta2 G, so that you can use R_rm X and R_rm CNOT but not R_rm R_X(03)."
},

{
    "location": "dev/extending-blocks/#Adding-Tags-to-Your-Blocks-1",
    "page": "Extending Blocks",
    "title": "Adding Tags to Your Blocks",
    "category": "section",
    "text": "A tag refers toDaggered - G^dagger   We use Base.adjoint(G) to generate a daggered block.\nIf a block is hermitian, do nothing,\nFor many blocks, e.g. Rx(0.3), we can still define some rule like Base.adjoint(r::RotationBlock) = (res = copy(r); res.theta = -r.theta; res),\nif even simple rule does not exist, its mat function will fall back to mat(G)\'.\nCachedBlock - the matrix of this block under current parameter will be stored in cache server for future use.\nG |> cache can be useful when you are trying to compile a block into a reuseable matrix, to use cache, you should define cache_key."
},

{
    "location": "dev/benchmark/#",
    "page": "Benchmark with ProjectQ",
    "title": "Benchmark with ProjectQ",
    "category": "page",
    "text": ""
},

{
    "location": "dev/benchmark/#Benchmark-with-ProjectQ-1",
    "page": "Benchmark with ProjectQ",
    "title": "Benchmark with ProjectQ",
    "category": "section",
    "text": "ProjectQ is an open source software framework for quantum computing. Here we present the single process benchmark result<img src=\"../assets/benchmarks/xyz-bench.png\"    alt=\"xyz\" height=\"200\">\n<img src=\"../assets/benchmarks/repeatxyz-bench.png\" alt=\"xyz\" height=\"200\">\n<img src=\"../assets/benchmarks/cxyz-bench.png\"      alt=\"xyz\" height=\"200\">\n<img src=\"../assets/benchmarks/crot-bench.png\"      alt=\"xyz\" height=\"200\">\n<img src=\"../assets/benchmarks/hgate-bench.png\"     alt=\"xyz\" height=\"200\">\n<img src=\"../assets/benchmarks/rot-bench.png\"       alt=\"xyz\" height=\"200\">From this benchmark, we see the performance of ProjectQ and Yao.jl are quite similar, both of them are close to the theoretical bound in performance.ProjectQ is a state of art quantum simulator, it kept the record of 45 qubit quantum circuit simulation for several months: https://arxiv.org/abs/1704.01127 4 It uses parallisms like SIMD, OpenMP, MPI to speed up calculation.ProjectQ has C++ backend, while Yao.jl uses pure julia. Yao.jl has significantly less overhead than ProjectQ, which benefits from julia’s jit and multile dispatch.In some benchmarks, like repeated blocks, Yao.jl can perform much better, this is an algorithmic win. Thanks to julia’s multiple dispatch, we can dispatch any advanced-speciallized algortihm to push the performance for frequently used gates easily, without touching the backend!"
},

{
    "location": "dev/benchmark/#CPU-Information-1",
    "page": "Benchmark with ProjectQ",
    "title": "CPU Information",
    "category": "section",
    "text": "Architecture:          x86_64\nCPU op-mode(s):        32-bit, 64-bit\nByte Order:            Little Endian\nCPU(s):                48\nOn-line CPU(s) list:   0-47\nThread(s) per core:    2\nCore(s) per socket:    12\nSocket(s):             2\nNUMA node(s):          2\nVendor ID:             GenuineIntel\nCPU family:            6\nModel:                 79\nStepping:              1\nCPU MHz:               2499.921\nBogoMIPS:              4401.40\nVirtualization:        VT-x\nL1d cache:             32K\nL1i cache:             32K\nL2 cache:              256K\nL3 cache:              30720K\nNUMA node0 CPU(s):     0-11,24-35\nNUMA node1 CPU(s):     12-23,36-47"
},

{
    "location": "dev/benchmark/#ProjectQ-1",
    "page": "Benchmark with ProjectQ",
    "title": "ProjectQ",
    "category": "section",
    "text": "We use ProjectQ v0.3.6 in this benchmark, with python version 3.6.Github Repo\nDamian S. Steiger, Thomas Häner, and Matthias Troyer \"ProjectQ: An Open Source Software Framework for Quantum Computing\" [arxiv:1612.08091]\nThomas Häner, Damian S. Steiger, Krysta M. Svore, and Matthias Troyer \"A Software Methodology for Compiling Quantum Programs\" [arxiv:1604.01401]"
},

{
    "location": "dev/benchmark/#Julia-Version-1",
    "page": "Benchmark with ProjectQ",
    "title": "Julia Version",
    "category": "section",
    "text": "Julia Version 0.7.0-alpha.147\nCommit 5e3259e (2018-06-16 18:43 UTC)\nPlatform Info:\n  OS: Linux (x86_64-linux-gnu)\n  CPU: Intel(R) Xeon(R) CPU E5-2650 v4 @ 2.20GHz\n  WORD_SIZE: 64\n  LIBM: libopenlibm\n  LLVM: libLLVM-6.0.0 (ORCJIT, broadwell)"
},

]}
