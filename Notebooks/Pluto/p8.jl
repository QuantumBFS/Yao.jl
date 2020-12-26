### A Pluto.jl notebook ###
# v0.12.17

using Markdown
using InteractiveUtils

# ╔═╡ 06657244-3d4d-11eb-3a7c-f79844513992
using Yao, YaoPlots

# ╔═╡ e0cfd952-3d49-11eb-195b-b34f3836e322
md"# Deutsch Algorithm"

# ╔═╡ 06c7fa22-3d4a-11eb-2f15-b7ef46b75be3
md"Deutsch's Algorithm was the first algorithm to prove that quantum computers can perform some tasks faster than classical ones, although the speedup in this case is a trivial one. 

The problem looks somewhat like this :- 

	Consider 4 functions 𝑓₀, 𝑓₁, 𝑓₂ and 𝑓₃. Each of them can take 0 or 1 as input. 

	𝑓₀(0) = 0, 𝑓₀(1) = 0 -> Constant function
	𝑓₁(0) = 0, 𝑓₁(1) = 1 -> Balanced function
	𝑓₂(0) = 1, 𝑓₂(1) = 0 -> Balanced function
	𝑓₃(0) = 1, 𝑓₃(1) = 1 -> Constant function
	
	Given one of these four functions at random, how many evaluations must we make to confirm whether the given function is balanced or constant.

Classically, it takes at least two evaluations to confirm whether the given function is balanced or constant."

# ╔═╡ 063623ea-3d4a-11eb-3471-ef67e8f31249
md"Using quantum computers, we can confirm whether the given function is balanced or not using one evaluation.

First we construct gates that correspond to the 4 functions. Here, let's consider a circuit, which takes the qubits $ |x〉 $ and $ |y〉, $ and returns the qubits $ |x〉 $ and $|y⊕𝑓_i(x)〉$ respectively, where $ i $ can be any random number between $ 0 $ to $ 3 $. Let's call this circuit $ F_i $ ."

# ╔═╡ f95221b4-4452-11eb-3cf6-d330a5c5aa11
YaoPlots.plot(put(2, 1:2 => label(chain(2), "𝐹ᵢ")))

# ╔═╡ 72324dca-4453-11eb-1c26-2b5c1031570b
md"Below is my implementation of 𝐹ᵢ"

# ╔═╡ f1f2f676-3d4c-11eb-307b-f7a7408372e0
begin
	𝐹₀ = chain(2)
	plot(𝐹₀)
end

# ╔═╡ 6514718e-3d4d-11eb-088b-9794ec4e7bc4
begin
	𝐹₁ = chain(2, control(1, 2=>X))
	plot(𝐹₁)
end

# ╔═╡ 7d3fd99c-3d4d-11eb-0100-67a39154fef1
begin
	𝐹₂ = chain(2, control(1, 2=>X), put(2=>X))
	plot(𝐹₂)
end

# ╔═╡ 92024f36-3d4d-11eb-3755-1f4538ed6003
begin
	𝐹₃ = chain(2, put(2=>X))
	plot(𝐹₃)
end

# ╔═╡ 2ef8834e-3d50-11eb-233c-fd44548a80b9
circuit = [𝐹₀ 𝐹₁ 𝐹₂ 𝐹₃]

# ╔═╡ 505429aa-3d50-11eb-333f-a75bc433b9ee
r = rand(0:3)

# ╔═╡ 938c4318-3d50-11eb-3060-31bc11556300
md" The new question now is :- 
	
	Given one of the four circuits at random, how many evaluations would it take to find whether the underlying function is balanced or constant?"

# ╔═╡ 559aa08a-3d56-11eb-2103-dd4114a41999
md"If, in the above circuits we pass $ 0 $ or $ 1 $, it'll be the same as classical computers -  it'll take 2 evaluations. 
To achieve this, we'll pass a superposition of $ 0 $ and $ 1 $, to the $ F_i $ circuit, and then we'll pass an H gate to the first qubit and measure it."

# ╔═╡ c1ca5030-4453-11eb-1814-dd9862cb5aa1
md"The final circuit for Deutsch Algorithm where the input is $ |01〉 $ looks somewhat like this"

# ╔═╡ f4e5006e-4453-11eb-3a08-a35438601cf1
plot(chain(2, repeat(H,1:2), put(1:2 => label(chain(2), "𝐹ᵢ")), put(1=>H), Measure(2, locs=1:1)))

# ╔═╡ 5dec54cc-4454-11eb-33fe-1b90858ea78a
md"Below is the final implementation, using the $ F_i $ we constructed before."

# ╔═╡ 5d52c8a8-3d50-11eb-1576-cb5f3485262b
begin
	input = ArrayReg(bit"10") #Remember, the circuit takes the qubits in reverse order
	result = input |> chain(2, repeat(H,1:2), put(1:2=>circuit[r+1]), put(1=>H)) |> r->measure(r,1)
end

# ╔═╡ a04dbca6-3d50-11eb-24c2-5dbef3190e76
result[1] == bit"1" ? "Balanced" : "Constant"

# ╔═╡ 8f5ac082-3d58-11eb-3952-8b8a74dc4e26
md"As you can see from the value of r, the result is correct."

# ╔═╡ f3568154-3ed2-11eb-125d-33a32b2030a7
md"# Deutsch–Jozsa Algorithm"

# ╔═╡ f5b13e08-3ed2-11eb-0790-d36bf95fe54f
md"The Deutsch-Jozsa Algorithm is the _general_ version of the Deutsch Algorithm. The problem is : --

	The functions are now of n variables. The inputs to each of these n variables can either be 0 or 1. So can be the output. The function can either be constant, where all the inputs get sent to 0 or all the inputs get sent to 1, or balanced, where half the inputs get sent to 0 and the rest get sent to 1.
	To illustrate this, let's take an example of 4 qubits. Which means 2⁴ possible inputs, as each input can either be 0 or 1.
	Let's check each input - 
	(0,0,0,0)	(1,1,1,1)
	(0,0,0,1)	(1,1,1,0)
	(0,0,1,0)	(1,1,0,1)
	(0,1,0,0)	(1,0,1,1)
	(1,0,0,0)	(0,1,1,1)
	(0,0,1,1)	(1,1,0,0)
	(1,1,0,0)	(0,0,1,1)
	(0,1,1,0)	(1,0,0,1)
	So if f(0,0,0,0) = 0, f(all 2⁴ combinations) = 0
	or f(0,0,0,0) = 1, f(all 2⁴ combinations) = 1
	The function is constant. Else, it's balanced."

# ╔═╡ 0a3fe586-3ed3-11eb-2c74-010072b424b2
md"Deutsch Algorithm is a case of Deutsch-Josza Algorithm, where the input is 1 qubit. Drawing inspiration from our above circuit, let's make a circuit for n inputs."

# ╔═╡ 2bb45ad8-3ed5-11eb-1647-8f67da7adba6
n = 3

# ╔═╡ 0c3fe0ac-3ed3-11eb-29f4-3f693e893928
begin
	ℱ₀ = chain(n+1)
	plot(ℱ₀)
end

# ╔═╡ 61492872-3ed5-11eb-2830-d33021e6bda6
begin
	ℱ₁ = chain(n+1, [control(k, n+1=>X) for k in 1:n])
	plot(ℱ₁)
end

# ╔═╡ 60951556-3ed5-11eb-0038-2576cbddd974
begin
	ℱ₂ = chain(n+1, chain(n+1, [control(k, n+1=>X) for k in 1:n]), put(n+1=>X))
	plot(ℱ₂)
end

# ╔═╡ 5f80f308-3ed5-11eb-3359-fddaa390f5ae
begin
	ℱ₃ = chain(n+1, put(n+1=>X))
	plot(ℱ₃)
end

# ╔═╡ ff428a74-3ed4-11eb-093d-85e41e536ad3
ℱ = [ℱ₀ ℱ₁ ℱ₂ ℱ₃]

# ╔═╡ d605a88a-3ed4-11eb-2189-7d6bb267dd25
newr = rand(0:3)

# ╔═╡ e8972db6-3ed4-11eb-2e01-0139eff96740
begin
	i = join(ArrayReg(bit"1"), zero_state(n))
	output = i |> chain(n+1, repeat(H, 1:n+1), put(1:n+1=>ℱ[newr+1]), repeat(H,1:n)) |> r->measure(r,1:n)
end

# ╔═╡ 8e9d0e2e-3ed8-11eb-326e-21f2893dadc5
md"If output of the measured qubits is $ $(\"0\"^n) $, then the function is constant, else if, the output is $ $(\"1\"^n) $, the function is balanced"

# ╔═╡ cc44243a-3ed8-11eb-2ef8-d98a6700769b
output == measure(zero_state(n)) ? "Constant" : "Balanced"

# ╔═╡ 0ed997be-4157-11eb-3f71-a16557d72c97
md"Please note, you can change the value of n above to get the Deutsch-Josza Algorithm for different inputs. $ n = 1 $ will give the Deutsch Algorithm."

# ╔═╡ Cell order:
# ╟─e0cfd952-3d49-11eb-195b-b34f3836e322
# ╟─06c7fa22-3d4a-11eb-2f15-b7ef46b75be3
# ╟─063623ea-3d4a-11eb-3471-ef67e8f31249
# ╠═06657244-3d4d-11eb-3a7c-f79844513992
# ╟─f95221b4-4452-11eb-3cf6-d330a5c5aa11
# ╟─72324dca-4453-11eb-1c26-2b5c1031570b
# ╠═f1f2f676-3d4c-11eb-307b-f7a7408372e0
# ╠═6514718e-3d4d-11eb-088b-9794ec4e7bc4
# ╠═7d3fd99c-3d4d-11eb-0100-67a39154fef1
# ╠═92024f36-3d4d-11eb-3755-1f4538ed6003
# ╠═2ef8834e-3d50-11eb-233c-fd44548a80b9
# ╠═505429aa-3d50-11eb-333f-a75bc433b9ee
# ╟─938c4318-3d50-11eb-3060-31bc11556300
# ╟─559aa08a-3d56-11eb-2103-dd4114a41999
# ╟─c1ca5030-4453-11eb-1814-dd9862cb5aa1
# ╟─f4e5006e-4453-11eb-3a08-a35438601cf1
# ╟─5dec54cc-4454-11eb-33fe-1b90858ea78a
# ╠═5d52c8a8-3d50-11eb-1576-cb5f3485262b
# ╠═a04dbca6-3d50-11eb-24c2-5dbef3190e76
# ╟─8f5ac082-3d58-11eb-3952-8b8a74dc4e26
# ╟─f3568154-3ed2-11eb-125d-33a32b2030a7
# ╟─f5b13e08-3ed2-11eb-0790-d36bf95fe54f
# ╟─0a3fe586-3ed3-11eb-2c74-010072b424b2
# ╠═2bb45ad8-3ed5-11eb-1647-8f67da7adba6
# ╠═0c3fe0ac-3ed3-11eb-29f4-3f693e893928
# ╠═61492872-3ed5-11eb-2830-d33021e6bda6
# ╠═60951556-3ed5-11eb-0038-2576cbddd974
# ╠═5f80f308-3ed5-11eb-3359-fddaa390f5ae
# ╠═ff428a74-3ed4-11eb-093d-85e41e536ad3
# ╠═d605a88a-3ed4-11eb-2189-7d6bb267dd25
# ╠═e8972db6-3ed4-11eb-2e01-0139eff96740
# ╟─8e9d0e2e-3ed8-11eb-326e-21f2893dadc5
# ╠═cc44243a-3ed8-11eb-2ef8-d98a6700769b
# ╟─0ed997be-4157-11eb-3f71-a16557d72c97
