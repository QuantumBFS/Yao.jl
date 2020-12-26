### A Pluto.jl notebook ###
# v0.12.17

using Markdown
using InteractiveUtils

# ╔═╡ 57209cca-1ede-11eb-283b-196a50e6f1eb
using Yao,YaoPlots

# ╔═╡ 76794562-1ed0-11eb-18ec-ad4020344ce6
md"# Arithmetic using qubits"

# ╔═╡ ad61776c-1ed9-11eb-20af-7d41b6e281c3
md"## Binary addition"

# ╔═╡ 949416ee-1ed0-11eb-2a86-dd52c9b1d5f9
md"Suppose we've to add two numbers in binary form! Say... $ 5 $ and $ 7 $."

# ╔═╡ aad0de2e-1ed0-11eb-3efc-95c0072fff76
md"In binary form, $ 5 $ can be represented by $ 101 $ and $ 7 $ can be represented by $ 111 $. Remember when adding two numbers in binary form, 

- $ 0 + 0 = 0 $
- $ 0 + 1 = 1 $
- $ 1 + 0 = 1 $
- $ 1 + 1 = 0 $ with a carry of $ 1 $

So adding $ 5 $ and $ 7 $ in binary form looks somewhat like this.
- $ \;\;\;\; ₁ \;₁\;₁\;₀ $  ← **Carry**
- $  \;\;\;\;\;\;1\; 0\; 1 $
- $ \;\; $ + $ \; 1\; 1\; 1 $
- $ \;\; $ _________
- $ \;\;\;1\;1\;0\;0 $

Starting from right, and moving to left

- $ 1 + 1 = 0 $ with a carry of $ 1 $
- $ 0 + 1 = 1 $ which is added to the carried value, which is $ 1 $, so $ 1 + 1 = 0 $ with a carry of $ 1 $, again
- $ 1 + 1 = 0 $ with a carry of $ 1 $. The result is added again to the carried value, which was $ 1 $, so $ 0 + 1 = 1 $
- The remaining carried value, which is $ 1 $, is put as it is.
"

# ╔═╡ c731fcb8-1ed7-11eb-2800-4fda7d5ae5e7
md"The result is $ \; [( 1 × 2^3 ) + ( 1 × 2^2 ) + ( 0 × 2^1 ) + ( 0 × 2^0 )] = 12. $"

# ╔═╡ b914c0b4-1ed9-11eb-37e9-8f1a60dbfcb2
md"#### Quantum addition circuit for one pair of qubits"

# ╔═╡ ec622eb0-1eda-11eb-0ca2-1bc4b4f1a730
md"We'll try making the adder circuit for addition of two numbers  $ (0-7) $. We'll need $ 3 $ qubits to represent each of the two numbers, which means a total of $ 6 $ qubits."

# ╔═╡ 30953b42-1ede-11eb-32ee-af55afa9221f
begin
	FirstNumber = [ArrayReg(bit"1") ArrayReg(bit"1") ArrayReg(bit"1")] #The first number is 7
	SecondNumber = [ArrayReg(bit"1") ArrayReg(bit"0") ArrayReg(bit"1")] #The second number is 5
end

# ╔═╡ 2ae7c4ec-1ee0-11eb-1c46-59d4d3084b39
md"For adding each pair of qubits, we'll need two more qubits to hold the carried in value and carried out value. Since the carry out of the 1st pair acts as the carry in of second pair, the carry out of the second pair acts as the carry in of the 3rd pair, we need 4 more qubits for carry in and carry out, with

- 1 qubit for the carry-in of first pair
- 1 qubit for the carry-out of first pair and the carry-in of the second pair
- 1 qubit for the carry-out of second pair and the carry-in of the third pair
- 1 qubit for the carry-out of third pair

In total, we require a total of $ 10 $ qubits to add two numbers in the range $ \; 0-7 $."

# ╔═╡ 1ac1e8c0-1f2d-11eb-1cc5-5986d94a86c2
md"So lets try making the quantum circuit for adding two qubits. We need a qubit for carry-in, which will be zero for the rightmost pair, and a qubit for carry-out, which will act as the carry in for the next pair"

# ╔═╡ 1d8ce7a2-1f2e-11eb-1b74-0d601958a2c9
md"Consider this circuit"

# ╔═╡ 802cf394-1f2d-11eb-23ad-95c475382371
begin
	OneqbQFA = chain(4, control(2:3, 4=>X), control(2, 3=>X), control([1 3], 4=>X), control(1, 3=>X))
	plot(OneqbQFA)
end

# ╔═╡ 36613c90-1f2e-11eb-1f5e-d3e079a8deda
md"
- The top qubit holds the carry-in value. 
- The bottom qubit has the state $ |0〉 $. 
- The 2nd and the 3rd qubits hold the pair to be added.
After passing throught the circuit,
- The top qubit holds the carry-in value. 
- The bottom qubit holds the carry-out value. 
- The 2nd qubit is as it was, while the 3rd qubit holds the addition of the 2nd and 3rd qubit.
"

# ╔═╡ 88d976e2-1f2e-11eb-0b7c-ad9557d124e6
md"### The use of CX gate in Arithmetics"

# ╔═╡ ade4a628-1f2e-11eb-32d0-c16546a16e44
md"Consider this circuit"

# ╔═╡ b307d638-1f2f-11eb-19ec-5fb58b49ff0f
begin
	a = chain(2, control(1, 2=>X))
	plot(a)
end

# ╔═╡ 31a37e02-1f30-11eb-3c16-494e05427f33
md"Lets try passing different values through this circuit"

# ╔═╡ 41c223ec-1f30-11eb-038b-efd7279954e6
measure((ArrayReg(bit"00") |> a)) #The output is 00, when we passed 00

# ╔═╡ 6ba13306-1f30-11eb-04c7-9f1c51a49915
measure(ArrayReg(bit"01") |> a) #The output is 11, when we passed 01
#Remember, the circuit takes the qubits as inputs, in reverse order. The rightmost qubit is the 1st qubit here, and since its |1〉, the 2nd qubit gets flipped to |1〉 too. 

# ╔═╡ 95dbc5be-1f30-11eb-232f-e72c7bfbda61
measure(ArrayReg(bit"10") |> a) #The output is 10, when we passed 10
#Remember, the circuit takes the qubits as inputs, in reverse order. The rightmost qubit is the 1st qubit here, and since its |0〉, the 2nd qubit is left untouched.

# ╔═╡ d33faf76-1f30-11eb-0dd7-3d1331633c0a
measure(ArrayReg(bit"11") |> a) #The output is 01, when we passed 11
#Remember, the circuit takes the qubits as inputs, in reverse order. The rightmost qubit is the 1st qubit here, and since its |1〉, the 2nd qubit is flipped to |0〉.

# ╔═╡ b3823ea8-1f31-11eb-0651-d55953af774a
md"Lets analyze the output
- When the top qubit is $ |0〉 $ and the bottom qubit is $ |0〉 $, the bottom qubit is left untouched.
- When the top qubit is $ |1〉 $ and the bottom qubit is $ |0〉 $, the bottom qubit is flipped to $ |1〉 $.
- When the top qubit is $ |0〉 $ and the bottom qubit is $ |1〉 $, the bottom qubit is left untouched.
- When the top qubit is $ |1〉 $ and the bottom qubit is $ |1〉 $, the bottom qubit is flipped to $ |0〉 $.
Compare this with,
- $ 0 + 0 = 0 $
- $ 0 + 1 = 1 $
- $ 1 + 0 = 1 $
- $ 1 + 1 = 0 $
In all the cases, the bottom qubit holds the added value.

How about adding 3 qubits?
"

# ╔═╡ c7b7511c-1f34-11eb-37ba-f71851aceb94
begin
	b = chain(3, control(2, 3=>X), control(1, 3=>X))
	plot(b)
end

# ╔═╡ fce93e40-1f34-11eb-3ea6-a11d129d7af3
measure.([(ArrayReg(bit"000") |> b) 
		(ArrayReg(bit"001") |> b) 
		(ArrayReg(bit"010") |> b) 
		(ArrayReg(bit"011") |> b) 
		(ArrayReg(bit"110") |> b) 
		(ArrayReg(bit"101") |> b) 
		(ArrayReg(bit"100") |> b) 
		(ArrayReg(bit"111") |> b)])
#If the output is not visible, click on the output to expand it.

# ╔═╡ 1604f776-1f36-11eb-03fc-c5575a528776
md"The toffoli gate acts as the carry-out. If both input qubits are $ |1〉 $, the 3rd qubit is flipped."

# ╔═╡ ba41d664-1f3a-11eb-2334-83fa55bc3bb6
md"### The Quantum Adder Circuit"

# ╔═╡ f4db1d44-1f3a-11eb-0b8c-4589d745d435
md"We already made the circuit for adding two qubits. Remember that the carry-out for the first pair, becomes the carry in for the second pair. With this, here's the circuit for a quantum adder for 2 numbers between $ 0-7 $."

# ╔═╡ 92b2e1b4-4457-11eb-22c0-7b5173d6bd97
plot(chain(10, put(1:4=>label(chain(4), "Full adder\nfor a pair\n of qubits")), put(4:7=>label(chain(4), "Full adder\nfor a pair\n of qubits")), put(7:10=>label(chain(4), "Full adder\nfor a pair\n of qubits"))))

# ╔═╡ 71d66a6e-4458-11eb-0a56-69919a6dbdca
md"Below is a complete circuit for quantum adder for 2 numbers between $ 0 - 7 $."

# ╔═╡ 412203a2-1f3b-11eb-3de7-45f7eccd697e
begin
	nqbQFA = chain(10, put(1:4=>OneqbQFA), put(4:7=>OneqbQFA), put(7:10=>OneqbQFA))
	plot(nqbQFA)
end

# ╔═╡ c2afc0f8-1f3b-11eb-0626-c5120a452e38
md"The input to the circuit being - "

# ╔═╡ e4b012f0-1f3b-11eb-1336-af9ba42a98c8
input = join(zero_state(1), SecondNumber[1], FirstNumber[1], zero_state(1), SecondNumber[2], FirstNumber[2], zero_state(1), SecondNumber[3], FirstNumber[3], zero_state(1))

# ╔═╡ 04c694e4-1f3c-11eb-1faf-0d08d391ce64
results = input |> nqbQFA |> r->measure(r, nshots=1024)

# ╔═╡ 1083740a-1f3c-11eb-2950-c56e4f20087c
stringres = reverse(string(Int(results[1]), base=2, pad=10)) #To convert it to string

# ╔═╡ 23e71498-1f3c-11eb-1c3e-2dac1694afeb
md"Remember, the 3, 6 and 9th qubits hold the added values. The 10 qubit holds the final carry-out, if any."

# ╔═╡ 4e89800a-1f3c-11eb-239f-f92807c81881
output = parse(Int64, reverse(stringres[3] * stringres[6] * stringres[9] * stringres[10]), base=2)

# ╔═╡ 270619d0-1f50-11eb-3a89-1187e12bd4f9
md"## Quantum subtractor"

# ╔═╡ 976e00e8-1f50-11eb-0d93-77e2ba841a09
md"Binary subtraction has a borrow instead of carry. The rules of binary subtraction look somewhat like this.
- $ 0 - 0 = 0 $
- $ 0 - 1 = 1 $ with a borrow of $ 1 $
- $ 1 - 0 = 1 $
- $ 1 - 1 = 0 $
"

# ╔═╡ 346af906-1f50-11eb-3286-dbf3014c8fab
begin
	OneqbSubtractor = chain(4, control(1, 3=>X), put(2=>X), control(2:3, 4=>X), control(1, 3=>X), control([1 3], 4=>X), put(2=>X), control(2, 3=>X), control(1, 3=>X))
	plot(OneqbSubtractor)
end

# ╔═╡ e2659b46-1f51-11eb-34db-dbc917b977dd
begin
	nqbQFS = chain(10, put(1:4=>OneqbSubtractor), put(4:7=>OneqbSubtractor), put(7:10=>OneqbSubtractor))
	plot(nqbQFS)
end

# ╔═╡ adeee882-1f55-11eb-27a4-d79963776e20
measure(join(zero_state(1), ArrayReg(bit"1"), ArrayReg(bit"0"),zero_state(1)) |> OneqbSubtractor)

# ╔═╡ b333400c-1f52-11eb-3775-e7e0ea35f93b
x = [ArrayReg(bit"1") ArrayReg(bit"0") ArrayReg(bit"0")]

# ╔═╡ c31d7fbe-1f52-11eb-098f-efab8ee8dc9f
y = [ArrayReg(bit"0") ArrayReg(bit"1") ArrayReg(bit"0")]

# ╔═╡ 0b18dec2-1f52-11eb-0dbb-510695c7b68b
input1 = join(zero_state(1), y[1], x[1], zero_state(1), y[2], x[2], zero_state(1), y[3], x[3], zero_state(1))

# ╔═╡ 1f828098-1f52-11eb-1d00-27f10270a814
result = input1 |> nqbQFS |> r->measure(r, nshots=1024)

# ╔═╡ 3cbd0f52-1f52-11eb-06f4-ffe29cccde57
stringsub = reverse(string(Int(result[1]), base=2, pad=10)) #To convert it to string

# ╔═╡ 658eec52-1f52-11eb-39aa-bbf1fcfb3517
out =  parse(Int64, reverse(stringsub[3] * stringsub[6] * stringsub[9] * stringsub[10]), base=2)

# ╔═╡ ffd40492-1f56-11eb-210d-ef6bf293244e
md"This circuit only subtracts numbers if the answer is expected to be positive. It can't solve for calculations like $ 5 - 6 = -1 $."

# ╔═╡ Cell order:
# ╟─76794562-1ed0-11eb-18ec-ad4020344ce6
# ╟─ad61776c-1ed9-11eb-20af-7d41b6e281c3
# ╟─949416ee-1ed0-11eb-2a86-dd52c9b1d5f9
# ╟─aad0de2e-1ed0-11eb-3efc-95c0072fff76
# ╟─c731fcb8-1ed7-11eb-2800-4fda7d5ae5e7
# ╟─b914c0b4-1ed9-11eb-37e9-8f1a60dbfcb2
# ╟─ec622eb0-1eda-11eb-0ca2-1bc4b4f1a730
# ╠═57209cca-1ede-11eb-283b-196a50e6f1eb
# ╠═30953b42-1ede-11eb-32ee-af55afa9221f
# ╟─2ae7c4ec-1ee0-11eb-1c46-59d4d3084b39
# ╟─1ac1e8c0-1f2d-11eb-1cc5-5986d94a86c2
# ╟─1d8ce7a2-1f2e-11eb-1b74-0d601958a2c9
# ╠═802cf394-1f2d-11eb-23ad-95c475382371
# ╟─36613c90-1f2e-11eb-1f5e-d3e079a8deda
# ╟─88d976e2-1f2e-11eb-0b7c-ad9557d124e6
# ╟─ade4a628-1f2e-11eb-32d0-c16546a16e44
# ╠═b307d638-1f2f-11eb-19ec-5fb58b49ff0f
# ╟─31a37e02-1f30-11eb-3c16-494e05427f33
# ╠═41c223ec-1f30-11eb-038b-efd7279954e6
# ╠═6ba13306-1f30-11eb-04c7-9f1c51a49915
# ╠═95dbc5be-1f30-11eb-232f-e72c7bfbda61
# ╠═d33faf76-1f30-11eb-0dd7-3d1331633c0a
# ╟─b3823ea8-1f31-11eb-0651-d55953af774a
# ╠═c7b7511c-1f34-11eb-37ba-f71851aceb94
# ╠═fce93e40-1f34-11eb-3ea6-a11d129d7af3
# ╟─1604f776-1f36-11eb-03fc-c5575a528776
# ╟─ba41d664-1f3a-11eb-2334-83fa55bc3bb6
# ╟─f4db1d44-1f3a-11eb-0b8c-4589d745d435
# ╟─92b2e1b4-4457-11eb-22c0-7b5173d6bd97
# ╟─71d66a6e-4458-11eb-0a56-69919a6dbdca
# ╠═412203a2-1f3b-11eb-3de7-45f7eccd697e
# ╟─c2afc0f8-1f3b-11eb-0626-c5120a452e38
# ╠═e4b012f0-1f3b-11eb-1336-af9ba42a98c8
# ╠═04c694e4-1f3c-11eb-1faf-0d08d391ce64
# ╠═1083740a-1f3c-11eb-2950-c56e4f20087c
# ╟─23e71498-1f3c-11eb-1c3e-2dac1694afeb
# ╠═4e89800a-1f3c-11eb-239f-f92807c81881
# ╟─270619d0-1f50-11eb-3a89-1187e12bd4f9
# ╟─976e00e8-1f50-11eb-0d93-77e2ba841a09
# ╠═346af906-1f50-11eb-3286-dbf3014c8fab
# ╠═e2659b46-1f51-11eb-34db-dbc917b977dd
# ╠═adeee882-1f55-11eb-27a4-d79963776e20
# ╠═b333400c-1f52-11eb-3775-e7e0ea35f93b
# ╠═c31d7fbe-1f52-11eb-098f-efab8ee8dc9f
# ╠═0b18dec2-1f52-11eb-0dbb-510695c7b68b
# ╠═1f828098-1f52-11eb-1d00-27f10270a814
# ╠═3cbd0f52-1f52-11eb-06f4-ffe29cccde57
# ╠═658eec52-1f52-11eb-39aa-bbf1fcfb3517
# ╟─ffd40492-1f56-11eb-210d-ef6bf293244e
