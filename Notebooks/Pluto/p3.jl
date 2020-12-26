### A Pluto.jl notebook ###
# v0.12.17

using Markdown
using InteractiveUtils

# ╔═╡ 57f367d6-025a-11eb-182a-773094da4307
using Yao, YaoPlots #calling the Yao and YaoPlots package

# ╔═╡ 3c9cf124-0257-11eb-16ce-0d857dce310f
md"# Using Yao - The basics of quantum computing in Julia using Yao.jl"

# ╔═╡ 5d5644b2-0257-11eb-36e9-7f4803cb3558
md"At the current moment, we don't have have quantum computers. How do we make quantum circuits then? Well, two things we can do right now are, simulate a few qubits or use the qubits created by corporates like IBM and D'Wave. Using Yao, we can simulate the qubits, without having a quantum computer\(based on the known mathematical and physics rules\), although the support to run your circuits on Yao using real qubits is coming to Yao soon."

# ╔═╡ 0f7d5bdc-0258-11eb-05bb-074d1b38c551
md"We can make a cicuit in Yao using *chain* function. For parameters we define the number of qubits and the operations we've to perform on them. Lets say we want to pass two qubits through two X gates. We do this by chain(number of qubits, operations). To use the X gate, we use the put() parameter. Run the cell below to see what happens."

# ╔═╡ ee15c64e-025a-11eb-2158-bd9cbea5f262
md" **\#\#** or single **#** sign mean comments in julia. It means that anything written after # or ## won't be read as a part of the program, in the line you used them."

# ╔═╡ dcf63604-0258-11eb-1466-fb21170c2e1a
let
	circuit = chain(2, put(1=>X), put(2=>X)); #define a variable "circuit" and "put" an X gate on the first qubit, and then put an X gate on the second qubit
	plot(circuit) #plot function, which takes a circuit for a parameter and prints the circuit diagram.
end

# ╔═╡ 841aa488-0259-11eb-351a-c1f1770b3a51
md"Assume we have 5 qubits and we have to pass each through an X gate. We can use the *repeat\(\)* parameter to pass the given number of qubits through the same gate."

# ╔═╡ af1aa2b4-0259-11eb-29fe-19ba9462deb9
plot(chain(5, repeat(X,1:5))) #plot function takes a circuit, which repeats the X gate on the qubits 1:5 or from 1st qubit to 5th qubit

# ╔═╡ 1efc3566-025a-11eb-2aae-fd953f22edfb
md"What about the Y, Z and H gate? "

# ╔═╡ 443afbfa-025a-11eb-03c6-e74bb5344e36
let
	circuit = chain(3, put(1=>Y), put(2=>Z), put(3=>H), repeat(Y, 1:2), repeat(Z, 1:2), repeat(H, [1 3]))
	plot(circuit)
end

# ╔═╡ 686ec0a0-025b-11eb-339e-1158d9b25529
md"What about multiqubit gates? We can use the control gate in Yao using the control\( \) parameter." 

# ╔═╡ 22f24af0-025c-11eb-23d3-b9945bc05a36
plot(chain(2, control(1, 2=>X))) #Which translates to if the state of the 1st qubit is |1>, perform X gate to the 2nd qubit or "put" the 2nd qubit through the X gate.

# ╔═╡ Cell order:
# ╟─3c9cf124-0257-11eb-16ce-0d857dce310f
# ╟─5d5644b2-0257-11eb-36e9-7f4803cb3558
# ╟─0f7d5bdc-0258-11eb-05bb-074d1b38c551
# ╟─ee15c64e-025a-11eb-2158-bd9cbea5f262
# ╠═57f367d6-025a-11eb-182a-773094da4307
# ╠═dcf63604-0258-11eb-1466-fb21170c2e1a
# ╟─841aa488-0259-11eb-351a-c1f1770b3a51
# ╠═af1aa2b4-0259-11eb-29fe-19ba9462deb9
# ╟─1efc3566-025a-11eb-2aae-fd953f22edfb
# ╠═443afbfa-025a-11eb-03c6-e74bb5344e36
# ╟─686ec0a0-025b-11eb-339e-1158d9b25529
# ╠═22f24af0-025c-11eb-23d3-b9945bc05a36
