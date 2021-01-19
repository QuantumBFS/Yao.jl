### A Pluto.jl notebook ###
# v0.12.18

using Markdown
using InteractiveUtils

# ╔═╡ 3636e5d4-0276-11eb-2346-b77b042e1240
using Yao, YaoPlots

# ╔═╡ d1930710-4466-11eb-3528-8bdcf0543578
begin
	using StatsBase: Histogram, fit
	using Plots: bar, scatter!, gr; gr()
	using BitBasis
	function plotmeasure(x::Array{BitStr{n,Int},1}) where n
		hist = fit(Histogram, Int.(x), 0:2^n)
		x = 0
		if(n<=3)
			s=8
		elseif(n>3 && n<=6)
			s=5
		elseif(n>6 && n<=10)
			s=3.2
		elseif(n>10 && n<=15)
			s=2
		elseif(n>15)
			s=1
		end
		bar(hist.edges[1] .- 0.5, hist.weights, legend=:none, size=(600*(2^n)/s,400), ylims=(0:maximum(hist.weights)), xlims=(0:2^n), grid=:false, ticks=false, border=:none, color=:lightblue, lc=:lightblue)
		scatter!(0:2^n-1, ones(2^n,1), markersize=0,
         series_annotations="|" .* string.(hist.edges[1]; base=2, pad=n) .* "⟩")
		scatter!(0:2^n-1, zeros(2^n,1) .+ maximum(hist.weights), markersize=0,
         series_annotations=string.(hist.weights))
	end
end

# ╔═╡ 1aba2418-0273-11eb-2fb6-a12d0afc33c6
md"# Applications
We'll discuss a few applications of qubits and quantum circuits. Namely the Bell States, Superdense Coding and Quantum Teleportation."

# ╔═╡ 84abe9cc-0273-11eb-0e38-c3a2b42c0848
md"## Bell States
The states, 

`` \frac{|00〉 + |11〉}{\sqrt2},  \frac{|01〉 + |10〉}{\sqrt2} ``

`` \frac{|00〉 - |11〉}{\sqrt2} `` and `` \frac{|01〉 - |10〉}{\sqrt2} ``

are known as the bell states. They are made by the bell circuit. The bell circuit looks like this."

# ╔═╡ 24727e9e-0276-11eb-344c-25a2ba5f138c
begin
	bellcircuit = chain(2, put(1=>H), control(1, 2=>X))
	plot(bellcircuit)
end

# ╔═╡ 6a117428-0276-11eb-156f-cf8597070a34
md"As you can see, the circuit takes in two qubits as input, and operates on them to give the bell states."

# ╔═╡ 932449a0-0277-11eb-0805-c533ef1ceebb
md"#### Feeding qubits to a circuit in Yao
There are many ways to create qubits to feed to quantum circuits in Yao."

# ╔═╡ 1a64822e-0278-11eb-1ed7-8f7f03623cee
q1 = ArrayReg(bit"00") #creating the system of two qubits with state |00>.

# ╔═╡ 6af54232-027d-11eb-087e-3b2516a14eb8
state(q1) #state of a qubit in vector form

# ╔═╡ 97a2930a-0278-11eb-1e5b-c1dc5b203022
md" **Note:** _**Normalizing** basically means making the summation of squares of probability amplitudes, equal to 1._" 

# ╔═╡ 1e60af8c-0279-11eb-21fd-77cbe8640448
md"Other ways of doing it are"

# ╔═╡ 23f8e17c-0287-11eb-34ab-25db7b60da63
ArrayReg(bit"00") + ArrayReg(bit"11") |> normalize! #Equivalent to (1/√2)*(|00>+|11>)

# ╔═╡ 3951f92c-0279-11eb-1097-0b9935025360
zero_state(2) #2 qubits, both with the state |0> and |0>

# ╔═╡ 033aa410-0279-11eb-3742-c7b3084f847b
md" There! We have a system of two qubits! Let's try feeding the qubits to the Bell circuit we made!"

# ╔═╡ 4a6f0f16-027b-11eb-0d9e-77a3d5c6f1ee
a = (q1 |> bellcircuit) #Passing the qubit q1 through the bell circuit

# ╔═╡ f6d9ad26-0285-11eb-115c-db22262790db
state(a)

# ╔═╡ 7f471eb2-0286-11eb-3fa4-45952f77d4eb
md"### Reverse Bell Circuit
A circuit which reverses the effects of the bell circuit on a qubit. It's represented in a circuit as follows"

# ╔═╡ a6ab9b2e-0286-11eb-382e-07d449a188c6
begin
	reversebellcircuit = chain(2, control(1,2=>X), put(1=>H))
	plot(reversebellcircuit)
end

# ╔═╡ cfa3d672-0286-11eb-3ce5-47a7afe1d336
md"You can input the output state you got from the bell circuit, into the reverse bell circuit, and you'll get back your original state. Why not give it a try?" 

# ╔═╡ 43241144-031c-11eb-01f4-d91cefa66359
md"Let's pass the qubits we got by passing two qubits in the Bell circuit, into the Reverse Bell Circuit."

# ╔═╡ 0f1b1ea0-031d-11eb-326c-65cd5aa41630
let
		res = (a |> reversebellcircuit)
		state(res)
end

# ╔═╡ f7b24140-0320-11eb-010d-db85da69ed7c
md"What do you think is the effect of single qubit gates on a qubit, which is entangled with another qubit? Lets check it out!"

# ╔═╡ 30a26136-0321-11eb-3375-af7b708a196d
begin
	singlequbitcircuit = chain(2, put(1=>X))
	plot(singlequbitcircuit)
end

# ╔═╡ 57be66c2-0326-11eb-0090-39e6b4f26b19
begin
	bellstate = ArrayReg(bit"00") + ArrayReg(bit"11") |> normalize!
	re = bellstate |> singlequbitcircuit
	state(re)
end

# ╔═╡ 68a743ea-0322-11eb-0039-d9a5ab8ad3f9
md"Can you notice how the circuit behaves as if its operating on one qubit? If the input is |{0}[1]〉 + |{1}[1]〉, it behaves like the bits in the curly braces are the state of one qubit, while the bits in sqare brackets are the state of the other qubit, and it operates on them accordingly?"

# ╔═╡ 4d4432a2-031d-11eb-28f1-f39a26b8b789
md"### Super-dense Coding and Quantum Teleportation"

# ╔═╡ 8012368e-031d-11eb-1aa6-f53e9ca5f88f
md"Suppose we have two entangled qubits in a bell state, represented by 
`` \frac{|00〉 + |11〉}{\sqrt2} .`` Alice and Bob are two friends. Alice gets one qubit and Bob gets the other one. Both of them travel far apart with their qubits, and not measuring their qubits so as to preserve the entangled state. The above information is the premise for both:
1. Super-dense coding
2. Quantum Teleportation"

# ╔═╡ 669e0b32-031e-11eb-231f-956bf10c9850
md"##### 1. Super-dense coding
Alice wants to send Bob two classical bits of information. That means, one of the four states `` 00, 01, 10 `` and `` 11 ``. How does she do this?
Lets say she achieves this by passing her qubits through one of the following gates, corresponding to the information she wants to send.

1. If she wants to send Bob `` 00 ``, then she'll send her qubit to Bob, as it is
2. If she wants to send Bob `` 01 ``, then she'll send her qubit to Bob, after passing it through X gate.
3. If she wants to send Bob `` 10 ``, then she'll send her qubit to Bob, after passing it through Z gate.
4. If she wants to send Bob `` 11 ``, then she'll send her qubit to Bob, after passing it through Y gate.

Bob will then run both the qubits through the reverse bell circuit and measure them and he'll get what Alice wanted to send him."

# ╔═╡ 65c3b24c-0324-11eb-11bb-8dfba3e35770
md"Measuring qubits in Yao can be done by using the measure function.

Assume you've the a qubit or a system of qubits in q, and you want to measure it, the syntax is,

	q |> r->measure(r, nshots=number_of_runs)
We can't determine the probability amplitudes of a qubit. But, we can run the measurement many times, and count the frequency of each bit combination it gives.

If you don't get that, just know the syntax and keep nshots=1024. 

Now, lets try measuring the result of the previous assignment!"

# ╔═╡ 0e2e6f62-0325-11eb-1637-116783c77ea8
measuredqubits = re |> r->measure(r, nshots=1024)

# ╔═╡ d623229e-04b3-11eb-37e4-65be46f8a1c2
md"Sometimes the measurement gives `` |01〉 `` and sometimes `` |10〉 ``. The probability of getting a `` |01〉 `` is same as getting the probability of `` |10〉 ``, which is `` (1/\sqrt2)^2 `` that is `` 0.5 `` ."

# ╔═╡ 42eda908-04b4-11eb-1d71-2b2df3ab0b82
md"Wanna see how we can test that? The below function plots the probability as histograms. You don't need to know its inner workings to use it."

# ╔═╡ 89e76d2e-04b4-11eb-0704-17b457103932
plotmeasure(measuredqubits)

# ╔═╡ b544dd14-446a-11eb-19c1-914694722f0e
md"The probability of the measurement giving `` |01〉 `` is $ $(sum(measuredqubits .== bit\"01\")/10.24)% $ and the number of times the measurement result is `` |10〉 `` is $ $(sum(measuredqubits .== bit\"10\")/10.24)\%. $"

# ╔═╡ ef6e1276-03d8-11eb-08b6-1fc082d158f6
md"Implementing the superdense coding."

# ╔═╡ 124eca24-03d9-11eb-3bca-c188b5d09404
begin
	Alice_and_Bobs_entangled_qubits = ArrayReg(bit"00") + ArrayReg(bit"11") |> normalize!
	input = ["00" "01" "10" "11"][rand(1:4)] #Assuming Alice wants to send one of these inputs to Bob.
end

# ╔═╡ 3e4d90dc-03df-11eb-371e-130d4339b472
state(Alice_and_Bobs_entangled_qubits)

# ╔═╡ ae574c4c-03da-11eb-2eb0-b1d06f9d61de
begin
	if(input == "00")
		Alices_circuit = chain(2)
	elseif(input == "01")
		Alices_circuit = chain(2, put(1=>X))
	elseif(input == "10")
		Alices_circuit = chain(2, put(1=>Z))
	elseif(input == "11") 
		Alices_circuit = chain(2, put(1=>Y))
	end
	plot(Alices_circuit)
end

# ╔═╡ adf60706-03db-11eb-2206-c7f5ac69ab41
Bobs_part = ((Alice_and_Bobs_entangled_qubits |> Alices_circuit) |> reversebellcircuit) |> r->measure(r, nshots=1024)
#The content in the first round bracket, outputs qubits, which are then fed to reversebellcircuit we saw before, which is then fed to the measure function.

# ╔═╡ 8570a5d0-03b7-11eb-0f75-09aad5a4b811
md"##### 2. Quantum Teleportation
Alice now has one more qubit, in the state `` a|0〉 + b|1〉.`` She wants to send her qubit to Bob, by changing the state of Bob's entangled qubit to Alice's extra qubit.

Confusing? Let's try naming the qubits. Alice and Bob have the qubits A and B respectively, which are entangled in the bell state. Alice has another qubit C. 

Alice wants to send her qubit to Bob by changing the state of B, to that of C. She wants the state of the qubit B to be `` a|0〉 + b|1〉. `` Alice doesn't know the values of a and b. Also, Bob can't make a measurement in any case as doing so will destroy B's state.

How does Alice do it? Well, she first passes both her qubits through the Reverse Bell circuit. She then measures both of her qubits. She gets one of the following outputs: `` |00〉, |01〉, |10〉 or |11〉, `` each with probability 1/4. Alice sends these two classical bits to Bob, via any classical means, example, she texts him or calls and tells him. Bob knows that corresponding to her message, there are 4 options, and he takes action accordingly for each.
1. He gets the message, `` |00〉, `` from Alice and knows that his qubit\(qubit B\) changed its state to that of qubit C.
2. He gets the message, `` |01〉, `` and knows that his qubit changed its state to `` a|1〉 + b|0〉, `` and he passes his qubit through X gate to change its state to that of qubit C.
3. He gets the message, `` |10〉, `` and knows that his qubit changed its state to `` a|0〉 - b|1〉, `` and he passes his qubit through Z gate to change its state to that of qubit C.
4. He gets the message, `` |11〉, `` and knows that his qubit changed its state to `` a|1〉 - b|0〉, `` and he passes his qubit through Y gate to change its state to that of qubit C."

# ╔═╡ 37d4357e-03be-11eb-3e1f-dda5a699af33
begin
	Alices_and_Bobs_entangled_qubits = ArrayReg(bit"00") + ArrayReg(bit"11") |> normalize!
	Alicequbit = rand_state(1) #This function creates a qubit with a random state.
	state(Alicequbit)
end

# ╔═╡ 6ca5a9cc-03be-11eb-2afa-295c81c21e35
state(Alices_and_Bobs_entangled_qubits)

# ╔═╡ af31a570-03be-11eb-1af1-03950ee1c51f
begin
	teleportationcircuit = chain(3, control(1,2=>X), put(1=>H))
	plot(teleportationcircuit)
end

# ╔═╡ 6498549a-03bf-11eb-0348-a9072154b85e
begin
	feeding = join(Alices_and_Bobs_entangled_qubits, Alicequbit) |> teleportationcircuit
	state(feeding)
end

# ╔═╡ 14abac76-03c1-11eb-0634-afc86a739215
md"The ``` join(qubit1, qubit2.....,qubitn) ``` function is used to join multiple qubits. Remember, the circuit takes the qubits as inputs, in reverse order."

# ╔═╡ b2e2fea0-03e4-11eb-1a20-157447a12ce5
Alices_measuredqubits = measure!(RemoveMeasured(), feeding, 1:2)

# ╔═╡ 5331ad20-03e5-11eb-1244-1b494c4afa02
if(Alices_measuredqubits == bit"00")
	Bobs_qubit = feeding
elseif(Alices_measuredqubits == bit"01")
	Bobs_qubit = feeding |> chain(1, put(1=>Z))
elseif(Alices_measuredqubits == bit"10")
	Bobs_qubit = feeding |> chain(1, put(1=>X))
else
	Bobs_qubit = feeding |> chain(1, put(1=>Y))
end

# ╔═╡ 8e222eee-03e2-11eb-3419-edfe12b7c61a
md"The ` RemoveMeasured() ` parameter in ` measure!() `, first measures the qubits, then removes the measured qubits from the system of qubits."

# ╔═╡ 49604160-03c4-11eb-2480-ff7abbe90508
state(Bobs_qubit)

# ╔═╡ bec22f54-03e7-11eb-34fd-0fce9ea7da8f
md"Is Alice's qubit same as Bob's qubit now?
You can see that for yourself!"

# ╔═╡ 14a7320c-03e8-11eb-0909-1354fd574659
[state(Alicequbit) state(Bobs_qubit)]

# ╔═╡ 340a69fe-068c-11eb-3b37-ed2694843113
md"Left side : State of Alice's qubit. Right side : State of Bob's qubit. Almost equivalent!"

# ╔═╡ Cell order:
# ╠═3636e5d4-0276-11eb-2346-b77b042e1240
# ╟─1aba2418-0273-11eb-2fb6-a12d0afc33c6
# ╟─84abe9cc-0273-11eb-0e38-c3a2b42c0848
# ╠═24727e9e-0276-11eb-344c-25a2ba5f138c
# ╟─6a117428-0276-11eb-156f-cf8597070a34
# ╟─932449a0-0277-11eb-0805-c533ef1ceebb
# ╠═1a64822e-0278-11eb-1ed7-8f7f03623cee
# ╠═6af54232-027d-11eb-087e-3b2516a14eb8
# ╟─97a2930a-0278-11eb-1e5b-c1dc5b203022
# ╟─1e60af8c-0279-11eb-21fd-77cbe8640448
# ╠═23f8e17c-0287-11eb-34ab-25db7b60da63
# ╠═3951f92c-0279-11eb-1097-0b9935025360
# ╟─033aa410-0279-11eb-3742-c7b3084f847b
# ╠═4a6f0f16-027b-11eb-0d9e-77a3d5c6f1ee
# ╠═f6d9ad26-0285-11eb-115c-db22262790db
# ╟─7f471eb2-0286-11eb-3fa4-45952f77d4eb
# ╠═a6ab9b2e-0286-11eb-382e-07d449a188c6
# ╟─cfa3d672-0286-11eb-3ce5-47a7afe1d336
# ╟─43241144-031c-11eb-01f4-d91cefa66359
# ╠═0f1b1ea0-031d-11eb-326c-65cd5aa41630
# ╟─f7b24140-0320-11eb-010d-db85da69ed7c
# ╠═30a26136-0321-11eb-3375-af7b708a196d
# ╠═57be66c2-0326-11eb-0090-39e6b4f26b19
# ╟─68a743ea-0322-11eb-0039-d9a5ab8ad3f9
# ╟─4d4432a2-031d-11eb-28f1-f39a26b8b789
# ╟─8012368e-031d-11eb-1aa6-f53e9ca5f88f
# ╟─669e0b32-031e-11eb-231f-956bf10c9850
# ╟─65c3b24c-0324-11eb-11bb-8dfba3e35770
# ╠═0e2e6f62-0325-11eb-1637-116783c77ea8
# ╟─d623229e-04b3-11eb-37e4-65be46f8a1c2
# ╟─42eda908-04b4-11eb-1d71-2b2df3ab0b82
# ╠═d1930710-4466-11eb-3528-8bdcf0543578
# ╠═89e76d2e-04b4-11eb-0704-17b457103932
# ╟─b544dd14-446a-11eb-19c1-914694722f0e
# ╟─ef6e1276-03d8-11eb-08b6-1fc082d158f6
# ╠═124eca24-03d9-11eb-3bca-c188b5d09404
# ╠═3e4d90dc-03df-11eb-371e-130d4339b472
# ╠═ae574c4c-03da-11eb-2eb0-b1d06f9d61de
# ╠═adf60706-03db-11eb-2206-c7f5ac69ab41
# ╟─8570a5d0-03b7-11eb-0f75-09aad5a4b811
# ╠═37d4357e-03be-11eb-3e1f-dda5a699af33
# ╠═6ca5a9cc-03be-11eb-2afa-295c81c21e35
# ╠═af31a570-03be-11eb-1af1-03950ee1c51f
# ╠═6498549a-03bf-11eb-0348-a9072154b85e
# ╟─14abac76-03c1-11eb-0634-afc86a739215
# ╠═b2e2fea0-03e4-11eb-1a20-157447a12ce5
# ╠═5331ad20-03e5-11eb-1244-1b494c4afa02
# ╟─8e222eee-03e2-11eb-3419-edfe12b7c61a
# ╠═49604160-03c4-11eb-2480-ff7abbe90508
# ╟─bec22f54-03e7-11eb-34fd-0fce9ea7da8f
# ╠═14a7320c-03e8-11eb-0909-1354fd574659
# ╟─340a69fe-068c-11eb-3b37-ed2694843113
