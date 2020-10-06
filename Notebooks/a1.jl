### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ b978fdae-05ac-11eb-21b9-a584bead4705
using Yao, YaoPlots

# ╔═╡ efa8e4a8-05ab-11eb-2faa-bb86b93de1fb
md"# Assignment Sheet 1"

# ╔═╡ 1002aa7c-05ac-11eb-3b42-87809ac716c4
md" **_Assignment 1_:** 
1. _Make the following circuit in Yao_.
2. _Make the qubits with state \"0000\", and feed it to the circuit._ Hint: You can use either of zero_state(number of qubits) function or ArrayReg(bit\" \") function
3. _Measure the state of all the 4 qubits 1024 times._"

# ╔═╡ 98ceb0e4-05ac-11eb-3058-e59aaaf58e82
begin
	a1_1 = chain(4, put(1=>X), repeat(H, 2:4), control(2, 1=>X), control(4, 3=>X), control(3, 1=>X), control(4, 3=>X), repeat(H, 1:4))
plot(a1_1)
end

# ╔═╡ 25293028-05ad-11eb-1e99-7f91895810fb
begin
	a1circuit = chain(4) #Complete the circuit
	plot(a1circuit)
end

# ╔═╡ 6db30ade-05ae-11eb-2343-e1a2986b6b54
a1circuit == a1_1 ? md"✅" : md"❌"

# ╔═╡ 7995ad56-05af-11eb-118a-c3ee4c34d824
fourzerostate = 0              #Remove that 0 and make the state "0000"

# ╔═╡ b816e74c-05b0-11eb-3f8c-09c2e70d3ac9
fourzerostate == zero_state(4) ? md"✅" : md"❌"

# ╔═╡ 16d5e24e-05b1-11eb-2352-8d897cc95f75
a1measuredstate = 0             #Remove the 0 and feed the qubits to the circuit you created, then measure them.

# ╔═╡ ce40470a-05c6-11eb-18b2-2996f097502f
let
	flag1 = sum(a1measuredstate .== bit"0000")
	flag2 = sum(a1measuredstate .== bit"1111")
	(flag1/10.24>38 && flag1/10.24<61) && (flag2/10.24>38 && flag2/10.24<61) && (flag1+flag2==1024) ? md"✅. The number of times 0000 comes as value after qubit's measurement is $(flag1/10.24) and number of times 1111 comes is $(flag2/10.24)" : md"❌"
end

# ╔═╡ 4c971cb6-0665-11eb-17b7-df3aa73ce750
md"**_Assignment 2:_** "

# ╔═╡ 7ec00838-0665-11eb-1d58-193cf8fcc24b
md"Did you know that you can use a circuit in another circuit, in Yao? What does that mean? Well..."

# ╔═╡ cc07db8c-0665-11eb-0d54-5b74156a06fc
#For example
let
	circuit1 = chain(2, put(1=>X), put(2=>Y))
	circuit2 = chain(4, put(1:2 => circuit1), put(3=>Z), put(4=>H))
	plot(circuit2)
end

# ╔═╡ 5cdf4a0c-0666-11eb-2ca9-c36074271ac2
md"1. _Make the Bell Circuit_
2. _Make the Reverse Bell Circuit_
3. _Make a circuit which takes two qubits and passes it through, first the Bell Circuit, and then the Reverse Bell Circuit. Use the two circuits you created above._
4. _Create the qubits_ \"00\", \"01\", \"10\" and \"11\", _and pass them through the circuit you created in step 3. Measure each time you pass them through the circuit, 1000 times_."

# ╔═╡ 7ed55e02-0667-11eb-1570-212652d5fe18
begin
	bellcircuit = chain(2) #complete the bell circuit
	plot(bellcircuit)
end

# ╔═╡ 766552de-067d-11eb-34fb-bbc0fc471071
bellcircuit == chain(2, put(1=>H), control(1,2=>X)) ? md"✅" : md"❌"

# ╔═╡ a59c3f42-0667-11eb-34e2-c9ab7e9080f2
begin
	reversebellcircuit = chain(2) #complete the reverse bell circuit
	plot(bellcircuit)
end

# ╔═╡ c2a9bb30-067d-11eb-0594-5d416dc1e763
reversebellcircuit == chain(2, control(1,2=>X), put(1=>H)) ? md"✅" : md"❌"

# ╔═╡ b0bfd050-0667-11eb-2ed7-1b6d4ea15816
begin
	bell_and_reverse_bell_circuit = chain(2) #complete the circuit as stated in step 3
	plot(bell_and_reverse_bell_circuit)
end

# ╔═╡ 5d52aca4-067f-11eb-3174-a966da065d76
bell_and_reverse_bell_circuit == chain(2, put(1=>H), control(1, 2=>H), control(1, 2=>H), put(1=>H)) ? md"✅" : md"❌"

# ╔═╡ d87106c6-067d-11eb-3beb-8bfea8d168a3
begin
	qubit00 = 0 #Remove the 0. Create qubits with state 00
	qubit01 = 0 #Remove the 0. Create qubits with state 01
	qubit10 = 0 #Remove the 0. Create qubits with state 10
	qubit11 = 0 #Remove the 0. Create qubits with state 11
end

# ╔═╡ d1019e06-067f-11eb-2d40-4d15fd34a149
(qubit00 == ArrayReg(bit"00")) && (qubit01 == ArrayReg(bit"10")) && (qubit10 == ArrayReg(bit"01")) && (qubit11 == ArrayReg(bit"11")) ? md"✅" : md"❌"

# ╔═╡ 1db39250-0681-11eb-30d5-2143291302de
md"Think of what the output will be, after measurement... Is the answer you're thinking of, same as the output you're getting after measurement?"

# ╔═╡ 4ccfcc26-067e-11eb-14c0-0fe93728efc2
begin
	measurement00 = 0 #Remove the 0. Feed the qubits 00, to the circuit created in step 3, and measure them 1000 times
	measurement01 = 0 #Remove the 0. Feed the qubits 01, to the circuit created in step 3, and measure them 1000 times
	measurement10 = 0 #Remove the 0. Feed the qubits 10, to the circuit created in step 3, and measure them 1000 times
	measurement11 = 0 #Remove the 0. Feed the qubits 11, to the circuit created in step 3, and measure them 1000 times
end

# ╔═╡ 479143ca-0680-11eb-13f2-6b4d089f2f37
(sum(measurement00 .== bit"00") + sum(measurement01 .== bit"10") + sum(measurement10 .== bit"01")  +  sum(measurement11 .== bit"11")) == 4000 ? md"✅" : md"❌"

# ╔═╡ c6efaa82-067e-11eb-0ad1-2518b517ea4e
md"_**Note:**_ If you're using ArrayReg(bit\" \") to create the qubits, the qubits are entered from right to left. For example, if you enter ArrayReg(\"1101\"), the computer will take it as 1011. Also, the value of measurement is read from right to left."

# ╔═╡ ff7b74ba-0680-11eb-2688-3fb96fc978c5
md"_**Assignment 3:**_"

# ╔═╡ 131c831a-0681-11eb-2bab-3d4cf5b23006
md"Suppose that Alice and Bob have 2 pairs of entangled qubits. Both the pairs are in the state $ \frac{|00> \;+\; |11>}{\sqrt2} $. Suppose Alice has an extra qubit, with completely random state." 

# ╔═╡ c89d84b4-0681-11eb-3c22-4def72fc3477
md"1. _Make the circuit for quantum teleportation_
2. _Pass the first pair of Alice and Bob's entangled qubit, with Alice's extra qubit, into the quantum teleportation circuit. Then collapse the first two qubit's states by measuring them._ Hint: Use the measure_remove!(qubit, location of qubits) function for this.
3. _Make the circuit for Superdense coding_
4. _Use the other pair of entangled qubits and superdense coding to convey the information Alice got from measuring her qubits from quantum teleportation circuit, to Bob._
5. _Use the above information to make Bob's qubit from first pair's state, to jump to Alice's extra qubit state._"


# ╔═╡ e59122aa-0687-11eb-02b0-a7f72525c5e7
begin
	Alice_and_Bobs_first_entangled_qubit = ArrayReg(bit"00") + ArrayReg(bit"11") |> normalize!
	Alice_and_Bobs_second_entangled_qubit = ArrayReg(bit"00") + ArrayReg(bit"11") |> normalize!
	Alices_extra_qubit = rand_state(1) |> normalize!
	state(Alices_extra_qubit)
end

# ╔═╡ b6670002-0688-11eb-3ecc-03476ce15431
begin
	quantumteleportationcircuit = chain(3) #Complete the circuit
	plot(quantumteleportationcircuit)
end

# ╔═╡ 458cf840-06e3-11eb-19fb-a5a4b0c70f0b
quantumteleportationcircuit == chain(3, put(1=>H), control(1, 2=>X)) ? md"✅" : md"❌"

# ╔═╡ fc6e0da0-068c-11eb-1c31-e92bc7455530
begin
	input_to_teleportation_circuit = join(Alice_and_Bobs_first_entangled_qubit, Alices_extra_qubit)
	state(input_to_teleportation_circuit)
end

# ╔═╡ 88f1d456-06df-11eb-1827-912c481bb7a4
input = 0
#Remove the "0". Pass the above created qubit through the teleportation circuit, measuring the first two qubits using measure_remove!() function. Hint: qubit |> circuit |> r->measure_remove!(r, m:n)

# ╔═╡ 79280796-06e3-11eb-1e5c-b5cea995a88a
(input == bit"00" || input == bit"11" || input==bit"10" || input==bit"01") && (typeof(input) != Int64) ? md"✅" : md"❌"

# ╔═╡ e933ab46-06df-11eb-312a-6f2e934b059d
md"The above measurement will act as the information for superdense coding circuit."

# ╔═╡ 26cc4008-06e0-11eb-0cdf-51954af7254d
begin
	if(input==bit"00")
		superdense_coding_circuit = chain(2)
	elseif(input==bit"01")
		superdense_coding_circuit = chain(2)
	elseif(input==bit"10")
		superdense_coding_circuit = chain(2)
	elseif(input==bit"11")
		superdense_coding_circuit = chain(2)
	end
	#Remember the bits are read from right to left
	#Complete the circuits for Alice's qubit
	plot(superdense_coding_circuit)
end

# ╔═╡ dc0b86be-06e4-11eb-24db-4f56cb821e0f
begin
	if(input==bit"00")
		superdense_coding_circuit == chain(2)
	elseif(input==bit"01")
		superdense_coding_circuit == chain(2, put(1=>Z))
	elseif(input==bit"10")
		superdense_coding_circuit == chain(2, put(1=>X))
	elseif(input==bit"11")
		superdense_coding_circuit == chain(2, put(1=>Y))
	end && typeof(input) != Int64 ? md"✅" : md"❌"
end

# ╔═╡ 28ccce76-06e1-11eb-1c70-b3d7779a062e
Bobs_part = ((Alice_and_Bobs_second_entangled_qubit |> superdense_coding_circuit) |> reversebellcircuit) |> r->measure(r, nshots=1000)

# ╔═╡ 2aaa0910-06e2-11eb-1d6c-0fae35763d48
#Bobs_part now contains the information Alice wanted to convey to Bob regarding his qubits. Use this information to make Bob's qubit's state jump to Alice's random qubit's state
begin
	if(Bobs_part[1]==bit"00")
		Bobs_qubit = input_to_teleportation_circuit |> chain(2)
	elseif(Bobs_part[1]==bit"01")
		Bobs_qubit = input_to_teleportation_circuit |> chain(2) #Complete the circuit
	elseif(Bobs_part[1]==bit"10")
		Bobs_qubit = input_to_teleportation_circuit |> chain(2) #Complete the circuit
	elseif(Bobs_part[1]==bit"11")
		Bobs_qubit = input_to_teleportation_circuit |> chain(2) #Complete the circuit
	end
	state(Bobs_qubit)
end

# ╔═╡ b1392da2-06e5-11eb-3632-7d96a1b81a24
begin
	if(Bobs_part[1]==bit"00")
		Bobs_qubit == input_to_teleportation_circuit |> chain(2)
	elseif(Bobs_part[1]==bit"01")
		Bobs_qubit == input_to_teleportation_circuit |> chain(2, put(1=>Z))
	elseif(Bobs_part[1]==bit"10")
		Bobs_qubit == input_to_teleportation_circuit |> chain(2, put(1=>X))
	elseif(Bobs_part[1]==bit"11")
		Bobs_qubit == input_to_teleportation_circuit |> chain(2, put(1=>Y)) 
	end && (sum(Bobs_part .== Bobs_part[1]) == 1000) ? md"✅" : md"❌"
end

# ╔═╡ 83df1840-06e7-11eb-2502-173dac5d4963
md"Seems to work... Although, wouldn't using the information from superdense coding make teleportation pointless."

# ╔═╡ Cell order:
# ╟─efa8e4a8-05ab-11eb-2faa-bb86b93de1fb
# ╠═b978fdae-05ac-11eb-21b9-a584bead4705
# ╟─1002aa7c-05ac-11eb-3b42-87809ac716c4
# ╟─98ceb0e4-05ac-11eb-3058-e59aaaf58e82
# ╠═25293028-05ad-11eb-1e99-7f91895810fb
# ╟─6db30ade-05ae-11eb-2343-e1a2986b6b54
# ╠═7995ad56-05af-11eb-118a-c3ee4c34d824
# ╟─b816e74c-05b0-11eb-3f8c-09c2e70d3ac9
# ╠═16d5e24e-05b1-11eb-2352-8d897cc95f75
# ╟─ce40470a-05c6-11eb-18b2-2996f097502f
# ╟─4c971cb6-0665-11eb-17b7-df3aa73ce750
# ╟─7ec00838-0665-11eb-1d58-193cf8fcc24b
# ╠═cc07db8c-0665-11eb-0d54-5b74156a06fc
# ╟─5cdf4a0c-0666-11eb-2ca9-c36074271ac2
# ╠═7ed55e02-0667-11eb-1570-212652d5fe18
# ╟─766552de-067d-11eb-34fb-bbc0fc471071
# ╠═a59c3f42-0667-11eb-34e2-c9ab7e9080f2
# ╟─c2a9bb30-067d-11eb-0594-5d416dc1e763
# ╠═b0bfd050-0667-11eb-2ed7-1b6d4ea15816
# ╟─5d52aca4-067f-11eb-3174-a966da065d76
# ╠═d87106c6-067d-11eb-3beb-8bfea8d168a3
# ╟─d1019e06-067f-11eb-2d40-4d15fd34a149
# ╟─1db39250-0681-11eb-30d5-2143291302de
# ╠═4ccfcc26-067e-11eb-14c0-0fe93728efc2
# ╟─479143ca-0680-11eb-13f2-6b4d089f2f37
# ╟─c6efaa82-067e-11eb-0ad1-2518b517ea4e
# ╟─ff7b74ba-0680-11eb-2688-3fb96fc978c5
# ╟─131c831a-0681-11eb-2bab-3d4cf5b23006
# ╟─c89d84b4-0681-11eb-3c22-4def72fc3477
# ╠═e59122aa-0687-11eb-02b0-a7f72525c5e7
# ╠═b6670002-0688-11eb-3ecc-03476ce15431
# ╟─458cf840-06e3-11eb-19fb-a5a4b0c70f0b
# ╠═fc6e0da0-068c-11eb-1c31-e92bc7455530
# ╠═88f1d456-06df-11eb-1827-912c481bb7a4
# ╟─79280796-06e3-11eb-1e5c-b5cea995a88a
# ╟─e933ab46-06df-11eb-312a-6f2e934b059d
# ╠═26cc4008-06e0-11eb-0cdf-51954af7254d
# ╟─dc0b86be-06e4-11eb-24db-4f56cb821e0f
# ╠═28ccce76-06e1-11eb-1c70-b3d7779a062e
# ╠═2aaa0910-06e2-11eb-1d6c-0fae35763d48
# ╟─b1392da2-06e5-11eb-3632-7d96a1b81a24
# ╟─83df1840-06e7-11eb-2502-173dac5d4963
