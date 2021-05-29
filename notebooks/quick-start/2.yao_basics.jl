### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 7697c424-7277-11eb-105d-150285a535c4
begin
	using Pkg
	Pkg.activate(mktempdir())
	Pkg.add("Yao")
	Pkg.add("YaoPlots")
	Pkg.add("YaoExtensions")
end

# ╔═╡ a49017b7-64b9-4519-9a91-457f2a303e1c
using Yao, YaoPlots

# ╔═╡ 9b314a8a-d521-4b97-a11b-c5226196c6d4
using YaoExtensions

# ╔═╡ 8cfe674b-a624-465f-9caa-f839ee83380e
md"""
# Yao Basics

First let's import the module by "using" it:
"""

# ╔═╡ 62c75c87-eaa5-4320-9b49-3c2f8a33397b
md"""
Yao represents quantum circuits/gates using **Yao Blocks**, they are a collection of Julia objects.


For example, you can implement a quantum Fourier transformation circuit as following:
"""

# ╔═╡ 763c233b-95cf-4a58-b3fb-ae3485a09f52
A(i, j) = control(i, j=>shift(2π/(1<<(i-j+1))))

# ╔═╡ 22075649-4798-4a89-8a37-02d6be489f3f
B(n, k) = chain(n, j==k ? put(k=>H) : A(j, k) for j in k:n)

# ╔═╡ 250eac58-7c75-482d-8ce7-a423e281fee5
qft(n) = chain(B(n, k) for k in 1:n)

# ╔═╡ 35f0bb9a-6676-4afa-864e-14e15f56ff0d
plot(qft(3))

# ╔═╡ 20d1d437-ceb3-4fb8-ab81-51a9aebe1bb3
md"""
here we use `plot` function to plot the generated quantum circuit, you can also use it to check what are the block `A` and block `B`.

The `chain` function is used to chain two blocks of same size together:
"""

# ╔═╡ cd837663-02bf-4540-9d75-1c0a456940c7
plot(chain(X, Y, H))

# ╔═╡ 76d40c22-3307-4ff8-b0cd-19d8cb815c72
md"the `put` function is used to put a gate on a specific location, it thus creates a larger block"

# ╔═╡ 81a4bb41-5790-42de-bf8c-ee909cc816df
plot(put(5, 2=>H))

# ╔═╡ 960629fa-1409-441d-a3c0-f5276d291c6c
md"""the control gates are defined using `control` block with another block as its input.

- the 1st argument is the number of qubits
- the 2nd argument is the controlled gate and its location
"""

# ╔═╡ a6aa360a-632a-46d7-b061-f48841042b13
plot(control(5, 3, 2=>H))

# ╔═╡ 575c593a-1957-4d97-84b6-622b9a99fa42
md"the quantum blocks defined for a quantum circuit eventually form a tree-like structure, they are also printed in this way:"

# ╔═╡ da1f61c6-f17a-4944-8c23-05ce1af83ca2
qft(3)

# ╔═╡ 3a7e4835-555d-4938-bba7-a0c0339bda5e
md"now we can define registers, Yao provides a builtin register type `ArrayReg` for full amplitude simulation:"

# ╔═╡ 3123fc39-a783-4ac9-b8ca-9c60c72a8a73
@doc ArrayReg

# ╔═╡ 01afe151-a6aa-4121-8db7-66560d3eec94
md"you can also create some common states using convenient functions, such as `rand_state`, `zero_state`:"

# ╔═╡ 43a17b19-16c3-4637-bcad-47bf0c562251
md"""
There are some implemented common components for building a quantum algorithm in the `YaoExtensions` package
"""

# ╔═╡ fc647d13-cfce-4093-a5af-6e049a8f66f5
md"""
for example you can build a variational quantum circuit quickly using `variational_circuit`
"""

# ╔═╡ de04aa00-70a7-4d12-8ff9-622c08f5eadf
variational_circuit(5, 3, [1=>2, 2=>3, 3=>4, 4=>5, 5=>1]) |> plot

# ╔═╡ 829d1f6d-7ee3-45d3-ba10-62529de07c54
md"now we can execute the circuit by on a register"

# ╔═╡ a41c3329-a644-48f4-a10d-c3c4887310ed
r = zero_state(5)

# ╔═╡ 3834a873-c821-4275-843a-11ee24b237b5
r |> variational_circuit(5, 3, [1=>2, 2=>3, 3=>4, 4=>5, 5=>1])

# ╔═╡ 260176ac-b108-4881-97c3-4c6aa6c52c6a
md"and calculate the expectation of a Hamiltonian"

# ╔═╡ 54ae27c2-8d35-4c8c-9fda-5715e1da1b1f
expect(heisenberg(5), r)

# ╔═╡ 4c9198b0-98d2-44ab-b4e6-a086342ab4c4
md"or we can also write it in a more compact form"

# ╔═╡ a3b75abb-03c0-4290-b42a-9b5b991ab85a
expect(heisenberg(5), r=>variational_circuit(5, 3, [1=>2, 2=>3, 3=>4, 4=>5, 5=>1]))

# ╔═╡ 170b8dd4-dbab-4a03-bd27-9e7fa0a9770e
md"now you can add the adjoint `'` mark to get the gradient together with the register using reverse mode differentiation"

# ╔═╡ 1d4839d5-8794-493f-a7aa-fcf20b6b3078
reg, ∇θ = expect'(heisenberg(5), zero_state(5)=>variational_circuit(5, 3, [1=>2, 2=>3, 3=>4, 4=>5, 5=>1]))

# ╔═╡ 2d02eb13-736b-49f3-988a-b37f5465d55a
md"""
GPU is supported by the `CuYao` package, you can install it using Pkg.add("CuYao"),
and switch your CPU register to a CUDA register using `cu` function
"""

# ╔═╡ Cell order:
# ╠═7697c424-7277-11eb-105d-150285a535c4
# ╟─8cfe674b-a624-465f-9caa-f839ee83380e
# ╠═a49017b7-64b9-4519-9a91-457f2a303e1c
# ╟─62c75c87-eaa5-4320-9b49-3c2f8a33397b
# ╠═763c233b-95cf-4a58-b3fb-ae3485a09f52
# ╠═22075649-4798-4a89-8a37-02d6be489f3f
# ╠═250eac58-7c75-482d-8ce7-a423e281fee5
# ╠═35f0bb9a-6676-4afa-864e-14e15f56ff0d
# ╟─20d1d437-ceb3-4fb8-ab81-51a9aebe1bb3
# ╠═cd837663-02bf-4540-9d75-1c0a456940c7
# ╟─76d40c22-3307-4ff8-b0cd-19d8cb815c72
# ╠═81a4bb41-5790-42de-bf8c-ee909cc816df
# ╟─960629fa-1409-441d-a3c0-f5276d291c6c
# ╠═a6aa360a-632a-46d7-b061-f48841042b13
# ╟─575c593a-1957-4d97-84b6-622b9a99fa42
# ╠═da1f61c6-f17a-4944-8c23-05ce1af83ca2
# ╟─3a7e4835-555d-4938-bba7-a0c0339bda5e
# ╠═3123fc39-a783-4ac9-b8ca-9c60c72a8a73
# ╟─01afe151-a6aa-4121-8db7-66560d3eec94
# ╟─43a17b19-16c3-4637-bcad-47bf0c562251
# ╠═9b314a8a-d521-4b97-a11b-c5226196c6d4
# ╟─fc647d13-cfce-4093-a5af-6e049a8f66f5
# ╠═de04aa00-70a7-4d12-8ff9-622c08f5eadf
# ╟─829d1f6d-7ee3-45d3-ba10-62529de07c54
# ╠═a41c3329-a644-48f4-a10d-c3c4887310ed
# ╠═3834a873-c821-4275-843a-11ee24b237b5
# ╟─260176ac-b108-4881-97c3-4c6aa6c52c6a
# ╠═54ae27c2-8d35-4c8c-9fda-5715e1da1b1f
# ╟─4c9198b0-98d2-44ab-b4e6-a086342ab4c4
# ╠═a3b75abb-03c0-4290-b42a-9b5b991ab85a
# ╟─170b8dd4-dbab-4a03-bd27-9e7fa0a9770e
# ╠═1d4839d5-8794-493f-a7aa-fcf20b6b3078
# ╟─2d02eb13-736b-49f3-988a-b37f5465d55a
