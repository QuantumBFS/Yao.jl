### A Pluto.jl notebook ###
# v0.12.18

using Markdown
using InteractiveUtils

# ╔═╡ 653cd9ec-01a9-11eb-2e64-3f7ae853eb87
begin
	using Yao, YaoPlots
	plot(chain(1, put(1=>X)))
end

# ╔═╡ 6c350302-00b5-11eb-0537-cd523683f91c
md"# *Qubits*
Like the *bits* of a classical computer, quantum computers have their own fundamental unit of data called, a *qubit*."

# ╔═╡ 0260bd12-00b6-11eb-19e9-81c90f08fe7b
md"Qubits can make use of some quantum mechanical properties like superposition. For the sake of understanding how qubits work, imagine the quantum computer as a box, full of qubits. Now these qubits are objects which have some mathematical and physical properties, and can store data and can be used to manipulate data to get some computation done. 

Bits are represented by two states, `` 0 `` and `` 1 ``. At any time, a qubit is in a *superposition* of two states, represented by `` a|0〉 + b|1〉 ``. When we *measure* a qubit, its state *collapses* to, either `` |0〉 `` or `` |1〉 ``. The chances\(probability\) of a qubit collapsing to the state, `` |0〉 `` is `` a^2 `` and to `` |1〉 `` is `` b^2 ``. Hence, it must be satisfy `` |a^2| + |b^2| = 1 ``. 
a and b are also known as *probability amplitudes* of a given qubit."

# ╔═╡ df131fc4-00b9-11eb-09ed-9dcb647f6fda
md"**Note** : The notation of `` |\;〉 `` and `` 〈\;| `` are known as Dirac's notation, or the bra-ket notation.  
For this tutorial, you need to understand that column vectors(matrices of size `` n × 1``) are called kets and are represented by `` |\;〉 `` , and row vectors(matrices of size `` 1 × n ``) are called bras, and are represented by `` 〈\;| \; ``."

# ╔═╡ 91768fe2-019c-11eb-3ac7-7747249e9dca
md"# Working with qubits
So what do the terms, superposition and measurement, mean...? Well, to keep it simple, superposition of two or more states just means their linear combination. The superposition of states `` |0〉 `` and `` |1〉 `` just means a linear combination of `` |0〉 `` and `` |1〉 ``. If you still don't get it, no problem! Your intuition about superposition will build up by the time this tutorial reaches multiple qubits\(probably\).

When we use terms like measurement, we refer to *looking* at the state of the qubit. And yeah, we can't know the state of the qubit, because just when we look at it, it's state changes to `` |0〉 `` or `` |1〉 ``, and all the information about that qubit is lost. So the state of the qubit(the values of a and b) can't be determined."

# ╔═╡ c48bb1c0-019f-11eb-1210-e148231b166c
md"## Quantum Gates and Circuits
So consider that the state of a qubit is,  `` a|0〉 + b|1〉 ``. We want to do something with this..... say, we want to change the state to `` a|1〉 + b|0〉 ``... how do we manipulate the qubits or perform any operation on them? 

We use quantum gates, the building blocks of quantum circuit, to manipulate qubits to get some task done. 

Note: For the information that follows, please note that we can represent a qubit or a system of qubits with their state vector. Consider the qubit, `` a|0〉 + b|1〉 ``, we can represent this as 
`` \begin{bmatrix} a \\\ b \end{bmatrix} ``."

# ╔═╡ c101c26c-01a7-11eb-03b2-75598cd2d3bc
md"### Single qubit gates
As the name suggests, these gates take one qubit for an input, and give a qubit with changed state for an output.
##### 1. The X gate 
It changes the state of the qubit from `` a|0〉 + b|1〉 `` to `` a|1〉 + b|0〉 ``. It *flips* the state of the qubit.
Mathematically, its represented by 
`` \begin{bmatrix} 0 & 1 \\\ 1 & 0 \end{bmatrix} ``, and applying this gate to a qubit is mathematically equivalent to multiplying the vector representing the qubit to the above matrix. It looks somewhat like this, when implemented in a circuit."

# ╔═╡ 0378bb12-01aa-11eb-2671-09822e968fc3
md"##### 2. The Y gate
It changes the state of the qubit from `` a|0〉 + b|1〉 ``, to `` b|0〉 - a|1〉 ``. It does a *bit flip* and a *phase flip* at the same time.
The Y gate is mathematically represented by the matrix,
`` i \begin{bmatrix} 0 & -1 \\\ 1 & 0 \end{bmatrix} ``.
Mathematically, passing a qubit through this gate is equivalent to multiplying the state of the qubit, i.e., 
`` \begin{bmatrix} a \\\ b \end{bmatrix} ``,
to the above matrix.
It's represented in a circuit by"

# ╔═╡ d0832d3a-0228-11eb-1bc0-95096891f407
plot(chain(1, put(1=>Y)))

# ╔═╡ 809f6516-0228-11eb-32b6-0389c49e9ec6
md"##### 3. The Z gate
It changes the state of the qubit from `` a|0〉 + b|1〉 ``, to `` a|0〉 - b|1〉 ``. It does a *sign flip* on the qubit.
The Z gate is mathematically represented by the matrix,
`` \begin{bmatrix} 1 & 0 \\\ 0 & -1 \end{bmatrix} ``.
Mathematically, passing a qubit through this gate is equivalent to multiplying the state of the qubit, i.e., 
`` \begin{bmatrix} a \\\ b \end{bmatrix} ``,
to the above matrix. It looks like this when implemented in a circuit."

# ╔═╡ 9bce5884-0229-11eb-2dc5-c75d4eaa20bf
plot(chain(1,put(1=>Z)))

# ╔═╡ 144beaee-022a-11eb-1c9d-d359ca75064f
md" **_Note_**: *The matrix representation of the above three gates are known as Pauli's matrices, represented by `` \sigma_{x}, \;\sigma_y\;and\; \sigma_z ``, for the X gate, the Y gate and the Z gate, respectively*"


# ╔═╡ 0ba83070-0230-11eb-30e9-d579362bda98
md"##### 4. The H gate
When a qubit is passed through H gate, the `` |0〉 `` changes to `` \frac{1}{\sqrt2}(|0〉 +\; |1〉) ``, and the `` |1〉 `` changes to `` \frac{1}{\sqrt2}(|0〉 - |1〉) \\ ``. 

For an example, `` a|0〉 + b|1〉, `` changes to, `` \frac{a}{\sqrt2}(|0〉 + |1〉) +  \frac{b}{\sqrt2}(|0〉 - |1〉) ``. It can be simplified to give, `` \frac{a+b}{\sqrt2}|0〉 + \frac{a-b}{\sqrt2} |1〉 ``.
Mathematically, its represented by the matrix `` \frac{1}{\sqrt2} \begin{bmatrix} 1 & 1 \\\ 1 & -1 \end{bmatrix} `` and passing a qubit through the H gate is mathematically equivalent to multiplying the vector representing the state of the qubit, to the above matrix. In a circuit, the H gate is represented by"

# ╔═╡ 0a36b65c-0233-11eb-212c-5d6b03794af1
plot(chain(1,put(1=>H)))

# ╔═╡ 70fcb098-0250-11eb-051b-ff526b9be775
md"**_Note_**: *The state `` \frac{1}{\sqrt2}(|0〉 + |1〉) `` is often called `` |+〉 ``, and the state `` \frac{1}{\sqrt2}(|0〉 - |1〉) `` is often called `` |-〉 ``.* " 

# ╔═╡ 46c5e0d2-0233-11eb-387b-ad52dbad8553
md"### Multiqubit Gates
As the title suggests, these gates takes in and operate on more than one qubits."

# ╔═╡ 7edff156-0233-11eb-024b-090b7ae6481a
md"##### The CNOT gate
It takes two qubits as an input, and if the first qubit is a `` |1〉 `` the state of the second qubit is flipped to `` |0〉 `` if it was `` |1〉 ``, and `` |0〉 `` if it was `` |1〉 ``. If the state of the first qubit is `` |0〉 ``, no change is made to the second qubit. 
Mathematically, its represented by the matrix `` \begin{bmatrix} 1 & 0 & 0 & 0 \\\ 0 & 1 & 0 & 0 \\\ 0 & 0 & 0 & 1 \\\ 0 & 0 & 1 & 0 \end{bmatrix} ``, and passing two qubits through it is equivalent to first collecting the vector of two two qubits into one and multiplying it to the above matrix.
In a circuit, the CNOT or the **CX** gate is represented by"

# ╔═╡ f21da5fc-024f-11eb-355b-09ce90c6f7f6
plot(chain(2,control(1,2=>X)))

# ╔═╡ a9ab153c-0256-11eb-093f-71fa576c4034
md" **_Note:_** *To represent a system of two qubits, `` a_1 |00〉 + a_2 |01〉 + a_3 |10〉 + a_4 |11〉`` in vector form, we can write them as, `` \begin{bmatrix} a_1 \\a_2 \\a_3\\a_4 \end{bmatrix} ``, where `` |a_1^2| + |a_2^2| + |a_3^2| + |a_4^2| = 1. `` Also, we can use the CNOT or Control NOT or any other control gate(CY and CZ) to entangle two qubits.*"

# ╔═╡ Cell order:
# ╟─6c350302-00b5-11eb-0537-cd523683f91c
# ╟─0260bd12-00b6-11eb-19e9-81c90f08fe7b
# ╟─df131fc4-00b9-11eb-09ed-9dcb647f6fda
# ╟─91768fe2-019c-11eb-3ac7-7747249e9dca
# ╟─c48bb1c0-019f-11eb-1210-e148231b166c
# ╟─c101c26c-01a7-11eb-03b2-75598cd2d3bc
# ╟─653cd9ec-01a9-11eb-2e64-3f7ae853eb87
# ╟─0378bb12-01aa-11eb-2671-09822e968fc3
# ╟─d0832d3a-0228-11eb-1bc0-95096891f407
# ╟─809f6516-0228-11eb-32b6-0389c49e9ec6
# ╟─9bce5884-0229-11eb-2dc5-c75d4eaa20bf
# ╟─144beaee-022a-11eb-1c9d-d359ca75064f
# ╟─0ba83070-0230-11eb-30e9-d579362bda98
# ╟─0a36b65c-0233-11eb-212c-5d6b03794af1
# ╟─70fcb098-0250-11eb-051b-ff526b9be775
# ╟─46c5e0d2-0233-11eb-387b-ad52dbad8553
# ╟─7edff156-0233-11eb-024b-090b7ae6481a
# ╟─f21da5fc-024f-11eb-355b-09ce90c6f7f6
# ╟─a9ab153c-0256-11eb-093f-71fa576c4034
