### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 2b3d2532-1bac-491a-aeef-d9c29786341c
begin
	using Pkg
	Pkg.activate(mktempdir())
	Pkg.Registry.update()
	Pkg.add("Yao")
	Pkg.add("YaoPlots")
	Pkg.add("Plots")
	Pkg.add("BitBasis")
	Pkg.add("StatsBase")
end

# ╔═╡ e3cae266-2140-11eb-12f9-31b294a31586
using Yao, YaoPlots

# ╔═╡ 16d09514-2a5d-11eb-23da-b968d2ae5d16
begin
	using StatsBase: Histogram, fit
	using Plots: bar, scatter!, gr; gr()
	using BitBasis
	function plotmeasure(x::Array{BitStr{n,Int},1}, st="#") where n
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
		bar(hist.edges[1] .- 0.5, hist.weights, title = "Histogram", label="Found in "*string(st)*" tries", size=(600*(2^n)/s,400), ylims=(0:maximum(hist.weights)), xlims=(0:2^n), grid=:false, ticks=false, border=:none, color=:lightblue, lc=:lightblue, foreground_color_legend = nothing, background_color_legend = nothing)
		scatter!(0:2^n-1, ones(2^n,1), markersize=0, label=:none,
         series_annotations="|" .* string.(hist.edges[1]; base=2, pad=n) .* "⟩")
		scatter!(0:2^n-1, zeros(2^n,1) .+ maximum(hist.weights), markersize=0, label=:none, series_annotations=string.(hist.weights))
	end
end

# ╔═╡ ecb98520-212d-11eb-02e4-f3c89c254998
md"# Grover's Algorithm"

# ╔═╡ 0b9fb54a-212e-11eb-1f1d-8912b444cc0c
md"Suppose you've got 10 boxes, each with a paper with a random number on it, and you're searching for a number which may or may not be in one of the boxes. You'll have to search the first box, then the second, then the third... and so on, until you've found what you were looking for. Best case scenario - it just took one search (the number could be in the first box)! Worst case - it took 10 searches(it could've been in the last box, or in no box at all! ). 

Even if you get a bit clever, sort all the boxes according to the numbers in them, in ascending or descending order, and apply something like [binary search](https://en.wikipedia.org/wiki/Binary_search_algorithm), it'll almost take log₂(n) searches. 

Grover's Algorithm is a search algorithm, which solves the problem in O(`` \sqrt{n} ``) [time complexity](https://en.wikipedia.org/wiki/Time_complexity)(it takes `` 𝜋\sqrt{N}/4 `` searches, for one possible match)."

# ╔═╡ 88c22c5e-2130-11eb-2b73-5fbbbd662df9
md"## Sign flipping"

# ╔═╡ 326c3b46-2140-11eb-333e-27744c831983
md"Consider you've 3 qubits, with the state vector :- 

`` \frac{1}{\sqrt{8}} |000〉 + \frac{1}{\sqrt{8}} |001〉 + \frac{1}{\sqrt{8}} |010〉 + \frac{1}{\sqrt{8}} |011〉 + \frac{1}{\sqrt{8}} |100〉 + \frac{1}{\sqrt{8}} |101〉 + \frac{1}{\sqrt{8}} |110〉 + \frac{1}{\sqrt{8}} |111〉 ``"

# ╔═╡ c72bdf32-2140-11eb-1aec-55864296f0d3
begin
	qubits = uniform_state(3)
	state(qubits)
end

# ╔═╡ 746f121a-2141-11eb-2fab-5333ec478316
md"Suppose there was a circuit U, and if you passed the three qubits to U, the resultant state vector would look somewhat like this :-

`` \frac{1}{\sqrt{8}} |000〉 + \frac{1}{\sqrt{8}} |001〉 - \frac{1}{\sqrt{8}} |010〉 + \frac{1}{\sqrt{8}} |011〉 + \frac{1}{\sqrt{8}} |100〉 + \frac{1}{\sqrt{8}} |101〉 + \frac{1}{\sqrt{8}} |110〉 + \frac{1}{\sqrt{8}} |111〉 ``"

# ╔═╡ b8c52404-2141-11eb-0759-6db99f9ffa3a
md"One thing we know about this *magical* circuit is that its matrix representation looks like this, 

`` \begin{bmatrix}1 & 0 & 0 & 0 & 0 & 0 & 0 & 0\\0 & 1 & 0 & 0 & 0 & 0 & 0 & 0\\0 & 0 & -1 & 0 & 0 & 0 & 0 & 0\\0 & 0 & 0 & 1 & 0 & 0 & 0 & 0\\0 & 0 & 0 & 0 & 1 & 0 & 0 & 0\\0 & 0 & 0 & 0 & 0 & 1 & 0 & 0\\1 & 0 & 0 & 0 & 0 & 0 & 1 & 0\\1 & 0 & 0 & 0 & 0 & 0 & 0 & 1\end{bmatrix} `` 

Try multiplying the above state vector to the new matrix."

# ╔═╡ b47f24e2-2143-11eb-2e85-59a9f7762ddd
let
	U = rand(8,8) |> U->round.(round.(U * inv(U)))
	U[3,3] = -1
	U * state(qubits)
end

# ╔═╡ 433f40da-2145-11eb-35c0-6faaad23f32b
md"### Creating the magic circuit"

# ╔═╡ 9971e84e-28df-11eb-25e2-d9c71ae9dc42
md"You'll have to think about each circuit individually, according to the the element you want to flip. We're flipping `` \; |010〉 `` in this case. The circuit will be denoted by `` U_𝑓 ``."

# ╔═╡ 656cf846-444f-11eb-369e-f7919462e228
plot(chain(3, put(1:3 => label(chain(3), "U𝑓"))))

# ╔═╡ 4d81dbde-444f-11eb-1aae-7b666f5af174
md"Below is my implementation of this magic circuit"

# ╔═╡ 1f33e8c2-28e2-11eb-2f62-1fc0b46a05d3
begin
	U𝑓 = chain(3, repeat(X, [1 3]), control(1:2, 3=>Z), repeat(X, [1 3]))
	plot(U𝑓)
end

# ╔═╡ 9f8330b4-28e2-11eb-1a9d-1dce3076770d
md"The circuit for `` |011〉 `` will be"

# ╔═╡ bbc3dac6-28e2-11eb-0907-b72813ebe035
begin
	U𝑓_1 = chain(3, repeat(X, [3]), control(1:2, 3=>Z), repeat(X, [3]))
	plot(U𝑓_1)
end

# ╔═╡ 73b8c0aa-28e4-11eb-2c7c-b3177793ff92
state(uniform_state(3))

# ╔═╡ 72eb8480-28f5-11eb-3315-779a888c1d55
md"After passing the uniform qubits through U𝑓."

# ╔═╡ 089832b4-28f4-11eb-0c43-3de7e3518c9b
state(uniform_state(3) |> U𝑓)

# ╔═╡ d53e1414-28ea-11eb-35ab-81897180dd8b
md"## Amplitude Amplification"

# ╔═╡ cef6748e-28ea-11eb-1956-b9c7e4dd4d2b
md"Lets consider you want to increase one particular probability amplitude and decrease the rest."

# ╔═╡ f10966fe-28f5-11eb-0630-753ba509b76e
md"If your qubits were initially in the state :-


`` \frac{1}{\sqrt{8}} |000〉 + \frac{1}{\sqrt{8}} |001〉 + \frac{1}{\sqrt{8}} |010〉 + \frac{1}{\sqrt{8}} |011〉 + \frac{1}{\sqrt{8}} |100〉 + \frac{1}{\sqrt{8}} |101〉 + \frac{1}{\sqrt{8}} |110〉 + \frac{1}{\sqrt{8}} |111〉 ``"

# ╔═╡ fc46d108-28f5-11eb-0a1c-19b2ba4aa3df
md"Then you want them in the state :-"

# ╔═╡ 2a73a70e-28f6-11eb-1af0-0b5f034c2cf4
md"`` 1 × |010〉 ``"

# ╔═╡ 664e40c2-28f6-11eb-1957-5702b452c054
md"That means, ideally, the probability amplitude of `` |010〉 `` being close to `` 1 ``, while of others being close to `` 0 ``."

# ╔═╡ b5687650-28f6-11eb-12d3-eb2ddd6a7a2b
md"Inversion about the mean is a neat trick which helps you achieve that."

# ╔═╡ c966ad98-28f6-11eb-2f80-5fa5c652e0ea
md"### Inversion about the mean"

# ╔═╡ d0ee0d5e-28f6-11eb-38c5-8b634905b9ff
md"Its simple. I'll give an example."

# ╔═╡ e4be8aca-28f6-11eb-0f6b-35d51dcbce35
testmat = rand(10)

# ╔═╡ 210ef6b8-28f7-11eb-3277-a9fe7833f046
md"Lets plot it as a histogram"

# ╔═╡ 2af2a47c-28f7-11eb-1a3c-77de4ea4f692
bar(testmat)

# ╔═╡ f1fbacd6-28f6-11eb-27bc-e31d6628e6db
md"Say, I want to amplify the 4th element. Here's the procedure"

# ╔═╡ 95570f44-4470-11eb-17d4-83ffdf99888e
mean(x) = sum(x)/length(x)

# ╔═╡ 0fcf3598-28f7-11eb-2716-d7974741c9a8
begin
	matamplified = copy(testmat)
	matamplified[4] = -matamplified[4]
	matamplified = (2 .* mean(matamplified)) .- matamplified
end

# ╔═╡ cecd6894-446f-11eb-3ba2-876a7ff2acef
bar(matamplified)

# ╔═╡ e17009b0-28f9-11eb-0000-5db9eb38b481
md"What just happened:-
- In an array, choose the element you want to amplify.
- Flip the sign of that element.
- Then the new array with the element amplified, will have the elements :-
`` Amplified\; array = (2 × mean) - (the\; original\; array\; with\; the\; flipped\; element). ``
"

# ╔═╡ 98810d58-2a4b-11eb-25c2-9991e8613634
md"What if we do it again? Will it get amplified again?"

# ╔═╡ aa9a9d1a-2a4b-11eb-2433-69c46633f83c
begin
	newmatamplified = copy(matamplified)
	newmatamplified[4] = -newmatamplified[4]
	newmatamplified = (2 .* mean(newmatamplified)) .- newmatamplified
end

# ╔═╡ d6ff51ac-2a4b-11eb-10c8-b715525467d3
bar(newmatamplified)

# ╔═╡ bc7e15c4-2a56-11eb-1645-95457df3f2b6
md"So yes, it does amplified again"

# ╔═╡ dfe846d8-2a56-11eb-31cd-d3d400d0c0b2
md"### The Circuit Implementation"

# ╔═╡ f60823d4-2a56-11eb-2552-e540e863a617
md"The circuit for amplification looks like this, if the sign of the desired state is flipped"

# ╔═╡ 350bf890-4450-11eb-21cc-6db807eeb0e1
YaoPlots.plot(put(3, 1:3 => label(chain(3), "U𝜑")))

# ╔═╡ b2964bf8-4450-11eb-298e-9bf5088ef7ac
md"Again, below is my implementation of it."

# ╔═╡ c5c81956-2a59-11eb-3656-d35c46e52f2a
begin
	U𝜑 = chain(3, repeat(H, 1:3), repeat(X, 1:3), put(3=>H), control(1:2, 3=>X), put(3=>H), repeat(X, 1:3), repeat(H, 1:3))
	plot(U𝜑)
end

# ╔═╡ 923205f4-2a5c-11eb-2075-4bda871c8155
md"Combining this with the circuit for flipping, we get the Grovers Search Circuit, to which we feed qubits with _**uniform state**_."

# ╔═╡ d44b8aba-4450-11eb-39bd-e1e784c7c489
YaoPlots.plot(chain(3, put(1:3 => label(chain(3), "U𝑓")), put(1:3 => label(chain(3), "U𝜑")), Measure(3, locs=1:3)))

# ╔═╡ 4fd7213a-4451-11eb-2c68-81536a97de0a
md"Below is the complete circuit implementation. Remember, the input to the circuit is  quits with uniform state."

# ╔═╡ d8fef778-2a5a-11eb-069c-351c0ff94b59
begin
	GroversSearchCircuit = chain(3, put(1:3=>U𝑓), put(1:3=>U𝜑), Measure(3, locs=1:3))
	plot(GroversSearchCircuit)
end

# ╔═╡ 19662fd2-2a5d-11eb-22fd-771b25ebce68
md"The below function plots the measurement function, just pass the measured values to it. You don't need to know its inner mechanisms to use it."

# ╔═╡ d4234cc0-2a89-11eb-0801-4bdffce7f359
md"Below is the implementation of the **_Grover's Search Algorithm_** to find `` |010〉 ``."

# ╔═╡ d2766870-2a5d-11eb-0484-7dc4c494b160
begin
	n = 3
	output = 0
	j = 0
	for i in 1:(2^3)
		input = uniform_state(n)
		global output = input |> GroversSearchCircuit |> r->measure(r, nshots=1000)
		if(output[1] == bit"010") #Checking for |010〉
			break
		end
		global j = i
	end
	plotmeasure(output, j+1)
end

# ╔═╡ 4f8749de-2a8f-11eb-0687-4b44e155f53c
md"You can keep running the above block of code, and you'll find that it takes a maximum of 4 tries to find the state `` |010〉 ``, which would be the worst case. Most of the times, you can find it in the first try!

Which sounds about right."

# ╔═╡ Cell order:
# ╠═2b3d2532-1bac-491a-aeef-d9c29786341c
# ╟─ecb98520-212d-11eb-02e4-f3c89c254998
# ╟─0b9fb54a-212e-11eb-1f1d-8912b444cc0c
# ╟─88c22c5e-2130-11eb-2b73-5fbbbd662df9
# ╟─326c3b46-2140-11eb-333e-27744c831983
# ╠═e3cae266-2140-11eb-12f9-31b294a31586
# ╠═c72bdf32-2140-11eb-1aec-55864296f0d3
# ╟─746f121a-2141-11eb-2fab-5333ec478316
# ╟─b8c52404-2141-11eb-0759-6db99f9ffa3a
# ╠═b47f24e2-2143-11eb-2e85-59a9f7762ddd
# ╟─433f40da-2145-11eb-35c0-6faaad23f32b
# ╟─9971e84e-28df-11eb-25e2-d9c71ae9dc42
# ╟─656cf846-444f-11eb-369e-f7919462e228
# ╟─4d81dbde-444f-11eb-1aae-7b666f5af174
# ╠═1f33e8c2-28e2-11eb-2f62-1fc0b46a05d3
# ╟─9f8330b4-28e2-11eb-1a9d-1dce3076770d
# ╠═bbc3dac6-28e2-11eb-0907-b72813ebe035
# ╠═73b8c0aa-28e4-11eb-2c7c-b3177793ff92
# ╟─72eb8480-28f5-11eb-3315-779a888c1d55
# ╠═089832b4-28f4-11eb-0c43-3de7e3518c9b
# ╟─d53e1414-28ea-11eb-35ab-81897180dd8b
# ╟─cef6748e-28ea-11eb-1956-b9c7e4dd4d2b
# ╟─f10966fe-28f5-11eb-0630-753ba509b76e
# ╟─fc46d108-28f5-11eb-0a1c-19b2ba4aa3df
# ╟─2a73a70e-28f6-11eb-1af0-0b5f034c2cf4
# ╟─664e40c2-28f6-11eb-1957-5702b452c054
# ╟─b5687650-28f6-11eb-12d3-eb2ddd6a7a2b
# ╟─c966ad98-28f6-11eb-2f80-5fa5c652e0ea
# ╟─d0ee0d5e-28f6-11eb-38c5-8b634905b9ff
# ╠═e4be8aca-28f6-11eb-0f6b-35d51dcbce35
# ╟─210ef6b8-28f7-11eb-3277-a9fe7833f046
# ╠═2af2a47c-28f7-11eb-1a3c-77de4ea4f692
# ╟─f1fbacd6-28f6-11eb-27bc-e31d6628e6db
# ╠═95570f44-4470-11eb-17d4-83ffdf99888e
# ╠═0fcf3598-28f7-11eb-2716-d7974741c9a8
# ╠═cecd6894-446f-11eb-3ba2-876a7ff2acef
# ╟─e17009b0-28f9-11eb-0000-5db9eb38b481
# ╟─98810d58-2a4b-11eb-25c2-9991e8613634
# ╠═aa9a9d1a-2a4b-11eb-2433-69c46633f83c
# ╠═d6ff51ac-2a4b-11eb-10c8-b715525467d3
# ╟─bc7e15c4-2a56-11eb-1645-95457df3f2b6
# ╟─dfe846d8-2a56-11eb-31cd-d3d400d0c0b2
# ╟─f60823d4-2a56-11eb-2552-e540e863a617
# ╟─350bf890-4450-11eb-21cc-6db807eeb0e1
# ╟─b2964bf8-4450-11eb-298e-9bf5088ef7ac
# ╠═c5c81956-2a59-11eb-3656-d35c46e52f2a
# ╟─923205f4-2a5c-11eb-2075-4bda871c8155
# ╟─d44b8aba-4450-11eb-39bd-e1e784c7c489
# ╟─4fd7213a-4451-11eb-2c68-81536a97de0a
# ╠═d8fef778-2a5a-11eb-069c-351c0ff94b59
# ╟─19662fd2-2a5d-11eb-22fd-771b25ebce68
# ╠═16d09514-2a5d-11eb-23da-b968d2ae5d16
# ╟─d4234cc0-2a89-11eb-0801-4bdffce7f359
# ╠═d2766870-2a5d-11eb-0484-7dc4c494b160
# ╟─4f8749de-2a8f-11eb-0687-4b44e155f53c
