### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ b9c84fff-8579-46fc-94cf-8bf6651ed0c0
begin
	using Pkg
	Pkg.activate(mktempdir())
	Pkg.Registry.update()
	Pkg.add("Yao")
	Pkg.add("YaoPlots")
end

# ╔═╡ 2d4047c2-3ea3-11eb-1076-3dff1cef4ec9
using Yao, YaoPlots

# ╔═╡ 6184d07e-3dd2-11eb-085f-af802694d25a
md"# Simon's Algorithm"

# ╔═╡ 8006c71c-3dd2-11eb-13b5-e32876e57d65
md"Simon's algorithm was the algorithm that inspired Shor in making the Shor's Algorithm. This is a great algorithm to have a look at hybrid algorithms, as this is a hybrid algorithm.

The problem is : --

	Suppose there's a binary string of length n. Binary string is a string composed of 0s and 1s. There's a function f, where f(x) = f(y), if and only if, y = x or y = x ⨁ s. x and y are binary strings of length n. s is a “secret” binary string of length n, where s is not all 0s. So, s can be any one of the possible (2ⁿ - 1) binary strings.

	We've to find the secret string s. 

	Example : - 
		Suppose that n = 3. 
		Suppose we find that f(000) = f(101), it means that 000 ⨁ s = 101.
		Remember, these are binary strings and not binary numbers. So 111 ⨁ 100 = 011.
		From the above information, we know that s is 101, as 000 ⨁ 101 = 101.

	The question is, how many times do we need to evaluate f, to find s?
	Also, we don't know what the secret string s or the function f are.

	Classically, we need at least 5 evaluations. We evaluate any four strings of length n, on the the function f, and they might all give different results. But the evaluation of the fifth string, on the function f, is bound to repeat one of the values from the previously evaluated four strings. Suppose f(010) and f(110) give the same result. That means, f(010) = f(110), which means 010 ⨁ s = 110. Adding 010 to both sides, 010 ⨁ 010 ⨁ s = 010 ⨁ 110 => 000 ⨁ s = 100, s = 100. 

	In general, for binary string of length n, we need to make (2ⁿ⁻¹ + 1) evaluations.
"

# ╔═╡ b2550450-3ea0-11eb-20ea-dd5194029a53
md"### Kronecker Product of Hadamard Gate
We know that the Hadamard Gate can be represented by the matrix, `` \frac{1}{\sqrt2} \begin{bmatrix} 1 & 1 \\\ 1 &-1 \end{bmatrix} ``.

- Applying H gate on 2 qubits, in the state `` |00〉 ``, we get, `` \frac{1}{2} (|00〉 + |01〉 + |10〉 + |11〉) ``
- Applying H gate on 2 qubits, in the state `` |01〉 ``, we get, `` \frac{1}{2} (|00〉 - |01〉 + |10〉 - |11〉) ``
- Applying H gate on 2 qubits, in the state `` |10〉 ``, we get, `` \frac{1}{2} (|00〉 + |01〉 - |10〉 - |11〉) ``
- Applying H gate on 2 qubits, in the state `` |11〉 ``, we get, `` \frac{1}{2} (|00〉 - |01〉 - |10〉 + |11〉) ``

The Matrix representation for `` H^{⊗2} `` can be given as, `` \frac{1}{2} \begin{bmatrix} 1 & 1 & 1 & 1 \\\ 1 & -1 & 1 & -1 \\\ 1 & 1 & -1 & -1 \\\ 1 & -1 & -1 & 1 \end{bmatrix} ``"

# ╔═╡ a6fc0830-3ea3-11eb-1421-4ff353057988
md"Which we can verify below"

# ╔═╡ cc70b2e6-3ea0-11eb-02b4-6702888f6d4a
Matrix(repeat(2, H, 1:2))

# ╔═╡ b176596e-3ea3-11eb-3d0a-fff2f58159bf
md"We can rewrite the above as

`` \frac{1}{\sqrt2} \begin{bmatrix} \begin{matrix} \frac{1}{\sqrt2} & \frac{1}{\sqrt2} \\\ \frac{1}{\sqrt2} &-\frac{1}{\sqrt2} \end{matrix} & \begin{matrix} \frac{1}{\sqrt2} & \frac{1}{\sqrt2} \\\ \frac{1}{\sqrt2} &-\frac{1}{\sqrt2} \end{matrix} \\\ \\\ \begin{matrix} \frac{1}{\sqrt2} & \frac{1}{\sqrt2} \\\ \frac{1}{\sqrt2} &-\frac{1}{\sqrt2} \end{matrix}  & \begin{matrix} -\frac{1}{\sqrt2} & -\frac{1}{\sqrt2} \\\ -\frac{1}{\sqrt2} &\frac{1}{\sqrt2} \end{matrix} \end{bmatrix} ``

Which can be again rewritten as 

`` H^{⊗2} = \frac{1}{\sqrt2} \begin{bmatrix} H & H \\\ H & -H \end{bmatrix} ``

Following this trend,

`` H^{⊗3} = \frac{1}{\sqrt2} \begin{bmatrix} H^{⊗2} & H^{⊗2} \\\ H^{⊗2} & -H^{⊗2} \end{bmatrix} ``

`` H^{⊗4} = \frac{1}{\sqrt2} \begin{bmatrix} H^{⊗3} & H^{⊗3} \\\ H^{⊗3} & -H^{⊗3} \end{bmatrix} `` 
- 
- 
-
`` H^{⊗n} = \frac{1}{\sqrt2} \begin{bmatrix} H^{⊗n-1} & H^{⊗n-1} \\\ H^{⊗n-1} & -H^{⊗n-1} \end{bmatrix} `` "

# ╔═╡ 1a13150c-4683-11eb-13a8-736ddb1a95f9
md"This is known as the Kronecker product of Hadamard Gate."

# ╔═╡ 2ce259f4-4683-11eb-3bb4-5555ecb46d2c
md"### Dot Product of binary strings"

# ╔═╡ 81a82610-4683-11eb-04e9-11c2275ce99c
md"*The dot product of two binary strings, a and b, both of length n, where `` a = a_0 a_1 a_2 .... a_{n-1} ``, and `` b = b_0 b_1 b_2 .... b_{n-1} ``, the  **dot product**  of `` a `` and `` b, a·b, `` is defined as*

` a · b = a₀ × b₀ ⨁ a₁ × b₁ ⨁ a₂ × b₂ .... aₙ₋₁ × bₙ₋₁ `

It's always equal to `` 0 `` or `` 1 ``.
If `` a = 0010 `` and ``  b = 0101 ``, then 

` a · b = 0 × 0 ⨁ 0 × 1 ⨁ 1 × 0 ⨁ 0 × 1 = 0 ⨁ 0 ⨁ 0 ⨁ 0 = 0 ` "

# ╔═╡ 16991654-4687-11eb-2516-3bb25117cc5e
md"Lets check out the dot products of all possible combinations for binary strings where `` n = 2. ``

`` \begin{bmatrix} 00·00 & 00·01 & 00·10 & 00·11 \\\ 01·00 & 01·01 & 01·10 & 01·11 \\\ 10·00 & 10·01 & 10·10 & 10·11 \\\ 11·00 & 11·01 & 11·10 & 11·11 \end{bmatrix} ``. Which calculates to `` \begin{bmatrix} 0 & 0 & 0 & 0 \\\ 0 & 1 & 0 & 1 \\\ 0 & 0 & 1 & 1 \\\ 0 & 1 & 1 & 0 \end{bmatrix} ``. "

# ╔═╡ bc0b8262-468e-11eb-0dee-936c2e985baa
md"Remember `` H^{⊗2} ``, which could be represented by, `` \frac{1}{2} \begin{bmatrix} 1 & 1 & 1 & 1 \\\ 1 & -1 & 1 & -1 \\\ 1 & 1 & -1 & -1 \\\ 1 & -1 & -1 & 1 \end{bmatrix} ? `` 

It can also be represented by, `` \frac{1}{2} \begin{bmatrix} (-1)^{00·00} & (-1)^{00·01} & (-1)^{00·10} & (-1)^{00·11} \\\ (-1)^{01·00} & (-1)^{01·01} & (-1)^{01·10} & (-1)^{01·11} \\\ (-1)^{10·00} & (-1)^{10·01} & (-1)^{10·10} & (-1)^{10·11} \\\ (-1)^{11·00} & (-1)^{11·01} & (-1)^{11·10} & (-1)^{11·11} \end{bmatrix} ``   "

# ╔═╡ f544222a-4691-11eb-2bee-8d4bc225e181
md"So yeah, we can use dot products to denote Knonecker products of Hadamard Gates"

# ╔═╡ 0e8001f0-4692-11eb-2457-43db7e80877f
md"Now, assume `` s = 11 ``. We're going to add the columns with the pairs ` x ` and ` x ⨁ s `. In other words, in this case, columns `` 1 `` and `` 4 ``, and, columns `` 2 `` and `` 3 ``.

Adding columns `` 1 `` and `` 4 ``,

`` \frac{1}{2} \begin{bmatrix} 1 \\\ 1 \\\ 1 \\\ 1 \end{bmatrix} + \frac{1}{2} \begin{bmatrix} 1 \\\ -1 \\\ -1 \\\ 1 \end{bmatrix} = \frac{1}{2} \begin{bmatrix} 2 \\\ 0 \\\ 0 \\\ 2 \end{bmatrix} ``

Similarly adding columns `` 2 `` and `` 3 ``,

`` \frac{1}{2} \begin{bmatrix} 1 \\\ -1 \\\ 1 \\\ -1 \end{bmatrix} + \frac{1}{2} \begin{bmatrix} 1 \\\ 1 \\\ -1 \\\ -1 \end{bmatrix} = \frac{1}{2} \begin{bmatrix} 2 \\\ 0 \\\ 0 \\\ -2 \end{bmatrix} ``"

# ╔═╡ 59cd0f38-4695-11eb-02ab-7b82274020a9
md"As the above vectors are state vectors, when doing the operation ` x ⨁ s `, we see that some probability amplitudes are getting amplified and some are getting cancelled. If you've studied exponents, you know that 
`` (−1)^{a⋅(b⊕s)} = (−1)^{a⋅b}(−1)^{a⋅s} ``. It means, if `` a⋅s = 0 ``, then `` (−1)^{a⋅(b⊕s)} = (−1)^{a⋅b} ``, hence they get added, and if, `` a⋅s = 1 ``, then  `` (−1)^{a⋅(b⊕s)} = -(−1)^{a⋅b} ``, hence they get cancelled out."

# ╔═╡ bf810cae-4699-11eb-3ef9-253fc690043e
md"### Circuit Implementation"

# ╔═╡ 319a200a-469a-11eb-0e9d-cb0f5d5c1a39
md"The circuit looks like this, where it takes a string of `` 0^{2n} `` as input, and the first n inputs, i.e. x, return x after passing through the circuit, and the next n inputs, i.e. y, return ` y ⨁ f(x) `, after passing through the circuit. Let's call this circuit `` U_𝑓 ``. This is for `` n = 2 ``."

# ╔═╡ 73c78fea-46ad-11eb-04f0-55a7f0b45d6a
plot(chain(2*2, repeat(H, 1:2), put(1:4 => label(chain(4), "U𝑓")), repeat(H, 1:2), Measure(4, locs=1:2)))

# ╔═╡ 4a5f9ac0-46ae-11eb-35c3-eb4cac737259
s = string(rand(1 : (2^2 - 1)), base=2, pad=2)

# ╔═╡ 14d1e556-46af-11eb-3a1e-152e76808279
begin
	if s == "11"
		U𝑓 = chain(4, control(1,3=>X), control(1,4=>X), control(2,3=>X), control(2,4=>X))
	elseif s == "01"
		U𝑓 = chain(4, control(1,3=>X), control(1,4=>X))
	elseif s == "10"
		U𝑓 = chain(4, control(2,3=>X), control(2,4=>X))
	end
	plot(U𝑓)
end

# ╔═╡ 716d8072-46d7-11eb-3837-fdfc895db226
begin
	SimonAlgoCircuit_for_n_2 = chain(4, repeat(H, 1:2), put(1:4=>U𝑓), repeat(H, 1:2))
	plot(SimonAlgoCircuit_for_n_2)
end

# ╔═╡ e4cfa0a4-46d7-11eb-3b3f-651d3646e5a2
output = zero_state(4) |> SimonAlgoCircuit_for_n_2 |> r->measure(r, 1:2, nshots=1024)

# ╔═╡ 50527e46-46d8-11eb-258f-d9943ac9187d
md"The reason it's a hybrid algorithm, is that we got two states, for `` n=2 ``, which have equal chances of being the secret string s. From here on, we've to classically deduce which of the measured states can be the output. Since s can't be `` 00 ``, s = $ $s $. 

Note that this implementation is specific to `` n=2 ``

Deduction gets really complicated as n increases, and while its very very unlikely, on real quantum machines, there's a chance that you'll never get the secret string s for any number of runs, or nshots. This algorithm doesn't have much use/application cases either. Shor was inspired by this algorithm to make a general period finding algorithm."

# ╔═╡ Cell order:
# ╠═b9c84fff-8579-46fc-94cf-8bf6651ed0c0
# ╟─6184d07e-3dd2-11eb-085f-af802694d25a
# ╟─8006c71c-3dd2-11eb-13b5-e32876e57d65
# ╟─b2550450-3ea0-11eb-20ea-dd5194029a53
# ╠═2d4047c2-3ea3-11eb-1076-3dff1cef4ec9
# ╟─a6fc0830-3ea3-11eb-1421-4ff353057988
# ╠═cc70b2e6-3ea0-11eb-02b4-6702888f6d4a
# ╟─b176596e-3ea3-11eb-3d0a-fff2f58159bf
# ╟─1a13150c-4683-11eb-13a8-736ddb1a95f9
# ╟─2ce259f4-4683-11eb-3bb4-5555ecb46d2c
# ╟─81a82610-4683-11eb-04e9-11c2275ce99c
# ╟─16991654-4687-11eb-2516-3bb25117cc5e
# ╟─bc0b8262-468e-11eb-0dee-936c2e985baa
# ╟─f544222a-4691-11eb-2bee-8d4bc225e181
# ╟─0e8001f0-4692-11eb-2457-43db7e80877f
# ╟─59cd0f38-4695-11eb-02ab-7b82274020a9
# ╟─bf810cae-4699-11eb-3ef9-253fc690043e
# ╟─319a200a-469a-11eb-0e9d-cb0f5d5c1a39
# ╟─73c78fea-46ad-11eb-04f0-55a7f0b45d6a
# ╠═4a5f9ac0-46ae-11eb-35c3-eb4cac737259
# ╠═14d1e556-46af-11eb-3a1e-152e76808279
# ╠═716d8072-46d7-11eb-3837-fdfc895db226
# ╠═e4cfa0a4-46d7-11eb-3b3f-651d3646e5a2
# ╟─50527e46-46d8-11eb-258f-d9943ac9187d
