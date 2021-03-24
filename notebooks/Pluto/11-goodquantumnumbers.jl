### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# ╔═╡ 7d69de62-8c9f-11eb-2700-d5000549e73a
using Yao, YaoExtensions

# ╔═╡ 3debb8fc-8ca2-11eb-0396-276292c75465
using LinearAlgebra: norm, eigen

# ╔═╡ 5490d554-8c9f-11eb-0144-657ba084051b
md"# Identifying good quantum numbers"

# ╔═╡ aa4a354e-8c9f-11eb-3b78-6bfec5ea9309
md"In quantum physics, a good quantum number `Q` can be identified by proving it commutes with the Hamiltonian
```math
[H, Q] = HQ-QH = 0
```

"

# ╔═╡ 13bb9b94-8ca0-11eb-0854-11639cf1e806
md"We are going to prove the Heisenberg Hamiltonian has both good quantum numbers $S_z=\sum_i s_z^{(i)}$ (i.e. $U(1)$ symmetry) and $\vec S^2 = S_z^2 + S_z^2 + S_y^2$ (i.e. $SU(2)$ symmetry)."

# ╔═╡ 88e7f9cc-8c9f-11eb-2108-cb3cc4e7e1ba
# Sz
function op_sz(n)
   sum(map(i->put(n, i=>Z), 1:n))
end

# ╔═╡ 995de21c-8c9f-11eb-0f5a-6783078dcb2e
# S^2
function op_s2(n)
   s = 1/4 * sum(map(op->sum(map(i->put(n, i=>op), 1:n))^2, [X, Y ,Z]))
end

# ╔═╡ dc94c1da-8ca0-11eb-2dc2-2960f9362060
md"if you see two `true`s, congratuations."

# ╔═╡ b6174834-8ca0-11eb-032a-afe47589dc82
iscommute(heisenberg(5), op_sz(5))

# ╔═╡ d4b156c2-8ca0-11eb-02ee-139bf317d1ce
iscommute(heisenberg(5), op_s2(5))

# ╔═╡ f2cac526-8ca0-11eb-2674-23474be64e57
md"### Whether a state is an eigenstate of an operator?"

# ╔═╡ 23e0a4c8-8ca1-11eb-2371-9531b47f35e9
md"Another interested using case is telling whether a state preserves some symmetry, that is

```math
Q|\psi\rangle = q |\psi\rangle
```
"

# ╔═╡ 74f43514-8ca1-11eb-1aa5-bd99e39b9b8b
md"For example, we are going to prove $\frac{1}{\sqrt 2}(|010101\rangle + |101010\rangle)$ has an $S_z$ good quantum number, but no good ${\vec S}^2$ quantum number"

# ╔═╡ da97b9b4-8ca0-11eb-3ffd-7184e1cbd10e
reg = product_state(bit"010101") + product_state(bit"101010") |> normalize!

# ╔═╡ 9e306820-8ca2-11eb-1dba-13fe7d1c1475
md"Apply $S_z$, if you see `0`, it means it has good quantum number $S_z=0$"

# ╔═╡ 1448f6b4-8ca1-11eb-0f20-65ec2419a8af
statevec(copy(reg) |> op_sz(6)) |> norm

# ╔═╡ c83ee8c4-8ca2-11eb-08dc-b5a4b31d4964
md"But when you apply $\vec S^2$, you will see `~4.24`"

# ╔═╡ 0c66c614-8ca2-11eb-3155-6df0e37cd76d
statevec(copy(reg) |> op_s2(6)) |> norm

# ╔═╡ 28035e24-8ca3-11eb-0ff4-f3da18535cf8
md"This is not possible, because it is not an eigenvalue of $\vec S^2$. For 6 spins, it should be $l(l+1), l\in \{0,1,2,3\}$. One can verify by diagonalizing the operator matrix, he will see `0, 2, 6, 12`."

# ╔═╡ 3acf5894-8ca3-11eb-112b-372a65330371
eigen(Matrix(op_s2(6))).values

# ╔═╡ cfd844c8-8ca3-11eb-1d3b-41111adea86c
md"Checking the eigenvalue along is usaually not enough, we should also check the state is indeed changed after applying $\vec S^2$."

# ╔═╡ 049e3534-8ca2-11eb-2a15-25eb296e7f19
(copy(reg) |> op_s2(6) |> normalize!) ≈ reg

# ╔═╡ 115e4180-8ca5-11eb-1731-7302ad21bac1
md"If you see a `false`, congratuations."

# ╔═╡ Cell order:
# ╟─5490d554-8c9f-11eb-0144-657ba084051b
# ╟─aa4a354e-8c9f-11eb-3b78-6bfec5ea9309
# ╠═7d69de62-8c9f-11eb-2700-d5000549e73a
# ╟─13bb9b94-8ca0-11eb-0854-11639cf1e806
# ╠═88e7f9cc-8c9f-11eb-2108-cb3cc4e7e1ba
# ╠═995de21c-8c9f-11eb-0f5a-6783078dcb2e
# ╟─dc94c1da-8ca0-11eb-2dc2-2960f9362060
# ╠═b6174834-8ca0-11eb-032a-afe47589dc82
# ╠═d4b156c2-8ca0-11eb-02ee-139bf317d1ce
# ╟─f2cac526-8ca0-11eb-2674-23474be64e57
# ╟─23e0a4c8-8ca1-11eb-2371-9531b47f35e9
# ╟─74f43514-8ca1-11eb-1aa5-bd99e39b9b8b
# ╠═da97b9b4-8ca0-11eb-3ffd-7184e1cbd10e
# ╠═3debb8fc-8ca2-11eb-0396-276292c75465
# ╟─9e306820-8ca2-11eb-1dba-13fe7d1c1475
# ╠═1448f6b4-8ca1-11eb-0f20-65ec2419a8af
# ╟─c83ee8c4-8ca2-11eb-08dc-b5a4b31d4964
# ╠═0c66c614-8ca2-11eb-3155-6df0e37cd76d
# ╟─28035e24-8ca3-11eb-0ff4-f3da18535cf8
# ╠═3acf5894-8ca3-11eb-112b-372a65330371
# ╟─cfd844c8-8ca3-11eb-1d3b-41111adea86c
# ╠═049e3534-8ca2-11eb-2a15-25eb296e7f19
# ╟─115e4180-8ca5-11eb-1731-7302ad21bac1
