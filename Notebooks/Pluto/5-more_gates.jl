### A Pluto.jl notebook ###
# v0.12.18

using Markdown
using InteractiveUtils

# ╔═╡ f6fa5d36-1dd4-11eb-1c33-3344c7697e82
using Yao, YaoPlots

# ╔═╡ 3c87d83e-1dca-11eb-2068-6fa8ceb4849a
md"## More Quantum Gates"

# ╔═╡ 5545465e-1dca-11eb-0273-6d32f757b4a2
md"As you might have thought, there do exist gates, other than the previously defined ones."

# ╔═╡ 8def8f9e-1dca-11eb-32cf-fdb2038a8feb
md"### Single qubit gates"

# ╔═╡ 83f65eb6-1dca-11eb-32cb-c577ad1d0b68
md"#### The `` R_𝜑^Z `` gate"

# ╔═╡ 9d8d835c-1dca-11eb-0ab7-01a80ca23e30
md"Passing a qubit through the `` R_𝜑^Z `` is equivalent to multiplying its state vector by `` \begin{bmatrix}1 & 0\\0 & e^{𝜑i}\end{bmatrix} ``.  
Remember, `` e^{iθ} = \cos(𝜃) + i\sin(𝜃) ``.

The `` R_𝜑^Z `` gate can be alternatively denoted by, `` \begin{bmatrix}e^{-𝜑i/2} & 0\\0 & e^{𝜑i/2}\end{bmatrix} ``. Its just the original matrix, multiplied by `` e^{-𝜑i/2} ``. We can do this since multiplication by `` e^{-𝜑i/2} `` is not *observable* during measurement as its a complex unit and `` | e^{iθ} | = |\cos(𝜃) + i\sin(𝜃)| = 1 . `` Remember that the abstract value of a complex number `` a + ib ``, i.e.,  `` |a + ib| = \sqrt{a^2 + b^2} `` and `` \sin^2θ + \cos^2θ = 1. ``

Considering a qubit, `` a|0〉 + b|0〉 , `` passing it through the `` R_\frac{𝞹}{2}^Z `` gate is equivalent to `` \begin{bmatrix}1 & 0\\0 & e^{𝜋i/2}\end{bmatrix} `` . And since `` \cos(\frac{𝞹}{2}) = 0`` and `` \sin(\frac{𝞹}{2}) = 1 , `` we can rewrite the above as, ``\begin{bmatrix}1 & 0\\0 & i\end{bmatrix}`` `` \begin{bmatrix}a\\b\end{bmatrix} ``."

# ╔═╡ 8cca417e-1dd4-11eb-2a18-bf9b80da3fd2
md"Lets try the above in Yao! The `` R_𝜑^Z `` gate can be used in Yao with the shift *block*. "

# ╔═╡ 1f7c993e-1dd5-11eb-2f13-7711d2426eb1
begin
	qubit = rand_state(1)
	state(qubit)
end

# ╔═╡ 5960e486-1dd5-11eb-2253-838f59b06d4c
state(qubit |> chain(1, put(1=>shift(π/2))))

# ╔═╡ ac10f6f8-1dd5-11eb-2cf1-29480480572a
md"As expected the output was `` \begin{bmatrix}a\\ib\end{bmatrix} ``. Remember, `` i = \sqrt{-1} `` and `` i^2 = -1 ``. (Also, note that in Julia, imaginary number 𝑖 is represented by im.)"

# ╔═╡ af22f8a8-1ddc-11eb-2958-bb45cdadf44f
md"Also, `` R_𝜋^Z `` gate is equivalent to Z gate."

# ╔═╡ df5a774e-1ddc-11eb-2e86-1dc8dd502e26
round.(Matrix(chain(1, put(1=>shift(π))))) == round.(Matrix(chain(1, put(1=>Z)))) #The round functions "rounds-off" the elements of the matrices

# ╔═╡ c1f87994-1e7c-11eb-3da3-21aa52e80520
md"Its represented in a circuit diagram by,"

# ╔═╡ cda277ce-1e7c-11eb-246c-0b97bb66ab73
plot(chain(1, put(1=>shift(π/3))))

# ╔═╡ a1173196-1dd9-11eb-394d-271a3871e181
md"#### The T Gate"

# ╔═╡ b1cc417a-1dd9-11eb-0156-67fd10743000
md"The T gate is equivalent to `` R_\frac{𝞹}{4}^Z . `` In its matrix form, it can be written as `` \begin{bmatrix}1 & 0\\0 & \frac{1 + i}{\sqrt{2}}\end{bmatrix} ``. Nevertheless, in Yao, it can be used by using the **T** *block* ."

# ╔═╡ 67b2bc30-1dda-11eb-2d81-edd411a207b2
state(qubit |> chain(1, put(1=>T)))

# ╔═╡ 7d546e10-1dda-11eb-2b9a-abe61e9edf6c
md"Also,"

# ╔═╡ 83dfc128-1dda-11eb-37d9-37b959ea5f58
Matrix(chain(1, put(1=>shift(π/4)))) == Matrix(chain(1, put(1=>T)))

# ╔═╡ ea6c8192-1e7c-11eb-30e5-8d65801ce703
md"Its circuit diagram representation looks somewhat like - "

# ╔═╡ feab87f0-1e7c-11eb-075b-a55e9d86184c
plot(chain(1, put(1=>T)))

# ╔═╡ 408ce964-1de4-11eb-2830-f14bdc87f899
md"#### The `` R_𝜑^X `` gate"

# ╔═╡ 09a069f0-1df6-11eb-19de-5da4bb572510
md"Similar to the `` R_𝜑^Z `` gate, the `` R_𝜑^X `` gate can be represented by `` \begin{bmatrix}\cos(\frac{𝜑}{2}) & -\sin(\frac{𝜑}{2})i\\-\sin(\frac{𝜑}{2})i & \cos(\frac{𝜑}{2})\end{bmatrix} ``."

# ╔═╡ 5a6f6786-1df7-11eb-0f06-5b229b0935bb
md"#### The `` R_𝜑^Y `` gate"

# ╔═╡ 6a775062-1df7-11eb-1ea2-7d5517774328
md"Similar to the `` R_𝜑^Z `` gate, the `` R_𝜑^X `` gate can be represented by `` \begin{bmatrix}\cos(\frac{𝜑}{2}) & -\sin(\frac{𝜑}{2})\\\sin(\frac{𝜑}{2}) & \cos(\frac{𝜑}{2})\end{bmatrix} ``."

# ╔═╡ 8d65504c-1df7-11eb-0f3a-93796bf5b7f9
md"They can be represented in Yao using the **Rx** and **Ry** *blocks* respectively" 

# ╔═╡ e10cd2c0-1e00-11eb-3c86-2d958e7aa92f
state(qubit |> chain(1, put(1=>Rx(π))))

# ╔═╡ 38071b04-1e00-11eb-1c6c-03f03ce37a92
state(qubit |> chain(1, put(1=>Ry(π))))

# ╔═╡ 451b4c6a-1e1f-11eb-18f0-e301d5d34c93
md"There's also an **Rz** *block* which which represents the alternative form of `` R_𝜑^Z `` matrix, i.e., `` \begin{bmatrix}e^{-𝜑i/2} & 0\\0 & e^{𝜑i/2}\end{bmatrix} ``."

# ╔═╡ ea7cda52-1e1f-11eb-2cdc-e9a04181acfb
state(qubit |> chain(1, put(1=>Rz(π))))

# ╔═╡ 8c6c62c4-1e20-11eb-1017-f51535591214
md"Note that the absolute value of both the shift and Rz blocks are same."

# ╔═╡ a214d034-1e20-11eb-2975-6f440fee2ee5
abs.(Matrix(chain(1, put(1=>shift(π/5))))) == abs.(Matrix(chain(1, put(1=>Rz(π/5)))))

# ╔═╡ 16d650bc-1e7d-11eb-39d0-33ba9cb031ed
md"The circuit diagram representations of Rx, Ry and Rz blocks, respectively"

# ╔═╡ 275a85be-1e7d-11eb-1114-f9872f35915d
plot(chain(1, put(1=>Rx(π/5)), put(1=>Ry(π/3)), put(1=>Rz(π/7))))

# ╔═╡ 3355c7c4-1e21-11eb-1d88-6f5a6b5c51a8
md"### Multi-qubit Gates"

# ╔═╡ 4afe09cc-1e21-11eb-1eec-6b6d78e76aae
md"#### The SWAP Gate"

# ╔═╡ 812b528e-1e21-11eb-3219-a9ce5de87933
md"The SWAP gate swaps the state of two qubits. It can be represented by the matrix, 
$\begin{bmatrix}1 & 0 & 0 & 0\\0 & 0 & 1 & 0\\0 & 1 & 0 & 0\\0 & 0 & 0 & 1\end{bmatrix}$. Its represented in Yao via the **swap** *block*."

# ╔═╡ b85aaad6-1e79-11eb-2d2a-2f0a8fdb9336
begin
	q = rand_state(2)
	state(q)
end

# ╔═╡ 63dd442a-1e7c-11eb-3c73-7186108b87b4
state(q |> chain(2, swap(1,2)))

# ╔═╡ 5c1a804c-1e7a-11eb-22ae-df5da105a8d7
md"The SWAP gate has the following circuit diagram representation"

# ╔═╡ cd7061a8-1e7d-11eb-3239-8f8410988851
plot(chain(2, swap(1,2)))

# ╔═╡ 5890257c-1e7e-11eb-2880-1d4257468ffc
md"There's a Toffoli gate, an S gate, a CSWAP gate, a `` \; C R_𝜑^{X,Y,Z} `` gate and probably a lot more. They can all be constructed using the existing blocks in Yao."

# ╔═╡ c1d38e3e-1e7e-11eb-07ac-5345d88b4781
let
	toffoli_Gate = chain(3, control(1:2, 3=>X)) #The toffoli gate
	plot(toffoli_Gate)
end

# ╔═╡ 512086b4-1e7f-11eb-1f4b-cde0db3c9734
let
	S_Gate = chain(1, put(1 => label(shift(π/2), "S"))) #The S gate
	plot(S_Gate)
end

# ╔═╡ 8c44d66e-1e7f-11eb-2821-5532c1fdb89d
let
	CRXYZ_Gates = chain(2, control(1, 2=>Rx(π/5)), control(1, 2=>Ry(π/7)), control(1, 2=>Rz(π/11)))
	plot(CRXYZ_Gates)
end

# ╔═╡ 07b469b8-1e85-11eb-1b2c-f3fb85382b66
let
	CSWAP = chain(3, control(1, 2:3=>SWAP)) #The CSWAP gate
	plot(CSWAP)
end

# ╔═╡ 96d92a88-4459-11eb-29ee-336cbba060a7
md"### The Measure Gate"

# ╔═╡ b23f15ca-4459-11eb-3089-f7ea50aaf5de
md"We already know how to measure the qubits. We can do it in the circuit itself too."

# ╔═╡ c9233378-4459-11eb-0aa9-af1cd8cef6ca
begin
	MeasureGate = chain(2, repeat(H, 1:2), Measure(2, locs=1:2))
	plot(MeasureGate)
end

# ╔═╡ 1615f882-445a-11eb-3a16-c76bb2305ff5
md"Note that now, when we measure them using the measure block, the output remains unchanged, even though we should've a 25% chance of getting `` |00〉, |01〉, |10〉 `` or `` |11〉 ``."

# ╔═╡ 9626495a-445a-11eb-0a2d-2168c66ad1e0
zero_state(2) |> MeasureGate |> r->measure(r, nshots=1024)

# ╔═╡ cd54fd7c-445a-11eb-0015-bd814cd6293f
md"Without the Measure gate,"

# ╔═╡ dbe0b9ee-445a-11eb-3526-29900707092e
zero_state(2) |> repeat(2, H, 1:2) |> r->measure(r, nshots=1024)

# ╔═╡ 06d1ed92-4485-11eb-3485-d1be36b9f68b
md"### The LabeledBlock"

# ╔═╡ 15f64d2c-4485-11eb-3749-a33d80bf5b6b
md"Its used for easily plotting circuits as boxes for simpler visualization."

# ╔═╡ 2c8d9af4-4485-11eb-238e-b36d910466fc
let
	a = chain(3, repeat(H, 1:2), put(3=>X))
	b = chain(2, repeat(Y, 1:2))
	circuit = chain(3, put(1:3 => label(a, "circuit a")), put(2:3 => label(b, "circuit b")))
	plot(circuit)
end

# ╔═╡ f5e2eb8a-4484-11eb-0957-41f14bbfc3d9
md"### Daggered Block"

# ╔═╡ 00b09d5a-4485-11eb-2857-011786a85254
md"We use Daggered block to build circuits which undo the effects of a particular circuit.

Let's take an example. Remember Bell Circuit?"

# ╔═╡ ec2e6fb4-4485-11eb-351d-4781925a47d3
begin
	bellcircuit = chain(2, put(1=>H), control(1, 2=>X))
	plot(bellcircuit)
end

# ╔═╡ 1791bfd0-4486-11eb-0107-e345d88b2ddb
state(zero_state(2) |> bellcircuit)

# ╔═╡ 61a0a0a0-4486-11eb-2f6a-750de59d5988
md"Building the Reverse Bell Circuit is as easy as,"

# ╔═╡ 771faeba-4486-11eb-07ac-4dc4d52d4726
state(zero_state(2) |> bellcircuit |> Daggered(bellcircuit))

# ╔═╡ b7d76bd4-4486-11eb-3565-ab0ef9238acf
md"Plotting the Daggered Block is a bit tricky! YaoPlots doesn't support DaggeredBlock yet. There are two alternatives to this."

# ╔═╡ 39890364-4488-11eb-22d7-33a8db179379
plot(Daggered(bellcircuit))

# ╔═╡ 4eb6a852-4488-11eb-0e42-7be38fca7571
md"One way is to use the label block"

# ╔═╡ 11a084ac-4487-11eb-30ea-539b38e0231f
let
	reversebellcircuit = put(2, 1:2 => label(Daggered(bellcircuit), "Bell\n Circuit†"))
	plot(reversebellcircuit)
end

# ╔═╡ 49ed44ca-4488-11eb-07dd-27f8ca6a1d41
md"Another way, is to use ` ' `."

# ╔═╡ 6325cf34-4488-11eb-0415-1d1f2fa0f1ba
plot(bellcircuit')

# ╔═╡ 6f5420f8-4488-11eb-3cf9-03675dc3c8db
md"Whats the difference between the DaggeredBlock and adjoint ` ' ` ?

One is a function of Yao, while another of Julia `Base`. Both perform the same operation on their input.

**Note:** _Its recommended to always use `'` over DaggeredBlock_."

# ╔═╡ f612e17a-475c-11eb-080a-ab0967411f64
md"### The Kron Block"

# ╔═╡ fc6c126c-475c-11eb-3efa-d5ffc4347358
md"Consider you've to make the below circuit."

# ╔═╡ 0c13552c-475d-11eb-23a8-ad67f6bb93bc
plot(kron(X,Y,Z,H,Rx(15)))

# ╔═╡ 2c87c612-475d-11eb-3af7-9542b157252f
md"Tired of using `put` block after `put` block? 

Presenting the kron block, where you can just input the gates on every qubit, one by one."

# ╔═╡ 616d3b96-475d-11eb-1500-5bbf4a263df8
plot(chain(5, put(1:3 => kron(X,Y,Z)), put(3:5 => kron(H,Rx(15),T))))

# ╔═╡ d643aa86-475d-11eb-3af7-0195206e2f64
md"### The Rotation Gate"

# ╔═╡ e39911c6-475d-11eb-2ef5-f743c27d0d07
md"Its the general version of the Rx, Ry and Rz gates you saw above"

# ╔═╡ fb813b74-475d-11eb-1323-6faf1b221dad
plot(chain(1, rot(X, 15), rot(Y, 16)))

# ╔═╡ Cell order:
# ╟─3c87d83e-1dca-11eb-2068-6fa8ceb4849a
# ╟─5545465e-1dca-11eb-0273-6d32f757b4a2
# ╟─8def8f9e-1dca-11eb-32cf-fdb2038a8feb
# ╟─83f65eb6-1dca-11eb-32cb-c577ad1d0b68
# ╟─9d8d835c-1dca-11eb-0ab7-01a80ca23e30
# ╟─8cca417e-1dd4-11eb-2a18-bf9b80da3fd2
# ╠═f6fa5d36-1dd4-11eb-1c33-3344c7697e82
# ╠═1f7c993e-1dd5-11eb-2f13-7711d2426eb1
# ╠═5960e486-1dd5-11eb-2253-838f59b06d4c
# ╟─ac10f6f8-1dd5-11eb-2cf1-29480480572a
# ╟─af22f8a8-1ddc-11eb-2958-bb45cdadf44f
# ╠═df5a774e-1ddc-11eb-2e86-1dc8dd502e26
# ╟─c1f87994-1e7c-11eb-3da3-21aa52e80520
# ╟─cda277ce-1e7c-11eb-246c-0b97bb66ab73
# ╟─a1173196-1dd9-11eb-394d-271a3871e181
# ╟─b1cc417a-1dd9-11eb-0156-67fd10743000
# ╠═67b2bc30-1dda-11eb-2d81-edd411a207b2
# ╟─7d546e10-1dda-11eb-2b9a-abe61e9edf6c
# ╠═83dfc128-1dda-11eb-37d9-37b959ea5f58
# ╟─ea6c8192-1e7c-11eb-30e5-8d65801ce703
# ╟─feab87f0-1e7c-11eb-075b-a55e9d86184c
# ╟─408ce964-1de4-11eb-2830-f14bdc87f899
# ╟─09a069f0-1df6-11eb-19de-5da4bb572510
# ╟─5a6f6786-1df7-11eb-0f06-5b229b0935bb
# ╟─6a775062-1df7-11eb-1ea2-7d5517774328
# ╟─8d65504c-1df7-11eb-0f3a-93796bf5b7f9
# ╠═e10cd2c0-1e00-11eb-3c86-2d958e7aa92f
# ╠═38071b04-1e00-11eb-1c6c-03f03ce37a92
# ╟─451b4c6a-1e1f-11eb-18f0-e301d5d34c93
# ╠═ea7cda52-1e1f-11eb-2cdc-e9a04181acfb
# ╟─8c6c62c4-1e20-11eb-1017-f51535591214
# ╠═a214d034-1e20-11eb-2975-6f440fee2ee5
# ╟─16d650bc-1e7d-11eb-39d0-33ba9cb031ed
# ╟─275a85be-1e7d-11eb-1114-f9872f35915d
# ╟─3355c7c4-1e21-11eb-1d88-6f5a6b5c51a8
# ╟─4afe09cc-1e21-11eb-1eec-6b6d78e76aae
# ╟─812b528e-1e21-11eb-3219-a9ce5de87933
# ╠═b85aaad6-1e79-11eb-2d2a-2f0a8fdb9336
# ╠═63dd442a-1e7c-11eb-3c73-7186108b87b4
# ╟─5c1a804c-1e7a-11eb-22ae-df5da105a8d7
# ╟─cd7061a8-1e7d-11eb-3239-8f8410988851
# ╟─5890257c-1e7e-11eb-2880-1d4257468ffc
# ╠═c1d38e3e-1e7e-11eb-07ac-5345d88b4781
# ╠═512086b4-1e7f-11eb-1f4b-cde0db3c9734
# ╠═8c44d66e-1e7f-11eb-2821-5532c1fdb89d
# ╠═07b469b8-1e85-11eb-1b2c-f3fb85382b66
# ╟─96d92a88-4459-11eb-29ee-336cbba060a7
# ╟─b23f15ca-4459-11eb-3089-f7ea50aaf5de
# ╠═c9233378-4459-11eb-0aa9-af1cd8cef6ca
# ╟─1615f882-445a-11eb-3a16-c76bb2305ff5
# ╠═9626495a-445a-11eb-0a2d-2168c66ad1e0
# ╟─cd54fd7c-445a-11eb-0015-bd814cd6293f
# ╠═dbe0b9ee-445a-11eb-3526-29900707092e
# ╟─06d1ed92-4485-11eb-3485-d1be36b9f68b
# ╟─15f64d2c-4485-11eb-3749-a33d80bf5b6b
# ╠═2c8d9af4-4485-11eb-238e-b36d910466fc
# ╟─f5e2eb8a-4484-11eb-0957-41f14bbfc3d9
# ╟─00b09d5a-4485-11eb-2857-011786a85254
# ╠═ec2e6fb4-4485-11eb-351d-4781925a47d3
# ╠═1791bfd0-4486-11eb-0107-e345d88b2ddb
# ╟─61a0a0a0-4486-11eb-2f6a-750de59d5988
# ╠═771faeba-4486-11eb-07ac-4dc4d52d4726
# ╟─b7d76bd4-4486-11eb-3565-ab0ef9238acf
# ╠═39890364-4488-11eb-22d7-33a8db179379
# ╟─4eb6a852-4488-11eb-0e42-7be38fca7571
# ╠═11a084ac-4487-11eb-30ea-539b38e0231f
# ╟─49ed44ca-4488-11eb-07dd-27f8ca6a1d41
# ╠═6325cf34-4488-11eb-0415-1d1f2fa0f1ba
# ╟─6f5420f8-4488-11eb-3cf9-03675dc3c8db
# ╟─f612e17a-475c-11eb-080a-ab0967411f64
# ╟─fc6c126c-475c-11eb-3efa-d5ffc4347358
# ╟─0c13552c-475d-11eb-23a8-ad67f6bb93bc
# ╟─2c87c612-475d-11eb-3af7-9542b157252f
# ╠═616d3b96-475d-11eb-1500-5bbf4a263df8
# ╟─d643aa86-475d-11eb-3af7-0195206e2f64
# ╟─e39911c6-475d-11eb-2ef5-f743c27d0d07
# ╠═fb813b74-475d-11eb-1323-6faf1b221dad
