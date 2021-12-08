### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 41e660a2-0d51-4a05-aacd-a78728d77b1c
md"""
### Variables and Some Basic Types

In Julia, you can define a variable similar to how you define it in Python, e.g we can define a `x` using `=` (assignment)
"""

# ╔═╡ c4f6b254-07e4-4ed7-8870-452818cb6e67
x = 1

# ╔═╡ 3b1e55f8-1616-462f-8996-6c49b92b1f0a
md"""every variable has a type, you can check it using `typeof`"""

# ╔═╡ 8742c25c-fcea-4799-a91c-04094f5d0e0b
typeof(x)

# ╔═╡ 662685dd-96e5-4a18-ac48-9c3056926a5c
md"By default Julia displays the output of the last operation. (You can suppress the output by adding `;` (a semicolon) at the end.)"

# ╔═╡ 905f2ff2-29fe-4c65-b955-f1a6675ff965
md"""
### Functions

In Julia, you can also define short-form, one-line functions using `=` (assignment) similar to how you write things mathematically.
"""

# ╔═╡ 8569be06-1f4a-47b2-aa64-b65027a3d2b8
f(x) = 2x

# ╔═╡ ee81eb70-168b-4b98-8a89-bcb8d2a5eb38
md"Typing the function's name gives information about the function. To call it we must use parentheses:"

# ╔═╡ b6bdc0df-54a2-4c9a-a4e2-e3aee8fdcd05
f

# ╔═╡ a72f47f4-0c75-4433-8afd-468609d0bbaf
f(2)

# ╔═╡ 34f81e8d-7714-40ea-b546-2383d7813eed
md"For longer functions we use the following syntax with the `function` keyword and `end`:"

# ╔═╡ b5b567da-ec59-4a9e-a70e-a226a828eb50
function g(x, y)
	z = x + y
	return z^2
end

# ╔═╡ 04f8a8d5-1bbb-42df-a0d0-ed80aa0ce957
md"""
### Control Flows

In Julia, there are `for`, `if` and `while`, they look like the following
"""

# ╔═╡ 10cd61db-09b9-4876-a3c9-2114578da639
begin
	s = 0
	for i in 1:10
		s += 1
	end
end

# ╔═╡ a1aa126f-15f3-44a2-8acb-ebccd8f16cfd
md"here `begin...end` is used to wrap a code block as Pluto required, you don't have to write it outside Pluto, we can now check the value of `s` by typing it again"

# ╔═╡ 9c002ca1-28ac-451c-ada2-8e55b90d3e64
s

# ╔═╡ 6154997e-a121-430e-bafe-c794412d9478
md"Here, `1:10` is a **range** representing the numbers from 1 to 10:"

# ╔═╡ 2ae4588f-6b88-47b0-928a-36e6df4bd755
typeof(1:10)

# ╔═╡ 201c7fd9-5723-46ce-84fa-7cb400a02f7b
md"""
the if else statement looks like the following
"""

# ╔═╡ 766d92dd-3df7-43f5-853c-43c4194aa842
if s < 10
	# do something
elseif 10 < s < 13
	# do something
else
	# do something
end

# ╔═╡ c7a414ca-a016-4959-8e06-080907ff244c
md"""
### Matrix and Array

Julia carries its own `Array` type, if you use Python, it is similar to `numpy.array` in Python except:

1. index starts from 1
2. the multi-dimensional index is column-wise

You can also have list comprehension:
"""

# ╔═╡ 382f7095-a3fe-4e99-9a2f-1b745f41830f
[i for i in 1:10]

# ╔═╡ e19c3b51-8405-4c47-9e7d-df809d281b9b
md"it works for multi-dimensional case too:"

# ╔═╡ d18227df-56d5-4879-ac26-9f45d35ba144
[(i, j) for i in 1:10, j in 1:5]

# ╔═╡ 4537e253-4954-4d2c-bc33-18aee3a2bdf5
md"most functions follow the same convention as numpy or MATLAB, e.g you can create a random matrix using:"

# ╔═╡ 301a8694-0b01-4515-ab40-d0f8564cfc78
rand(5, 5)

# ╔═╡ 749bf936-eefc-4dd5-b495-939d82f496a0
md"""
if you have question about using a function, you can always type question mark `?` in your REPL following the function name

```julia
julia> ?rand
```
"""

# ╔═╡ 0571129d-bdbf-4ff4-b607-dacb6d6d3911
md"""
### Package Manager & Environments

Julia carries its own package manager, you can use it as a normal package:

```julia
julia> using Pkg
```

to install a pacakge, you can use

```julia
julia> Pkg.add("Yao")
```

to remove a pacakge, you can use

```julia
julia> Pkg.rm("Yao")
```

All Julia program **runs inside an environment**, it is the global environment by default. It is usually recommended to run your notebook in a local environment, so we won't hit **any version conflicts** between different packages. 
"""

# ╔═╡ Cell order:
# ╟─41e660a2-0d51-4a05-aacd-a78728d77b1c
# ╠═c4f6b254-07e4-4ed7-8870-452818cb6e67
# ╟─3b1e55f8-1616-462f-8996-6c49b92b1f0a
# ╠═8742c25c-fcea-4799-a91c-04094f5d0e0b
# ╟─662685dd-96e5-4a18-ac48-9c3056926a5c
# ╟─905f2ff2-29fe-4c65-b955-f1a6675ff965
# ╠═8569be06-1f4a-47b2-aa64-b65027a3d2b8
# ╟─ee81eb70-168b-4b98-8a89-bcb8d2a5eb38
# ╠═b6bdc0df-54a2-4c9a-a4e2-e3aee8fdcd05
# ╠═a72f47f4-0c75-4433-8afd-468609d0bbaf
# ╟─34f81e8d-7714-40ea-b546-2383d7813eed
# ╠═b5b567da-ec59-4a9e-a70e-a226a828eb50
# ╟─04f8a8d5-1bbb-42df-a0d0-ed80aa0ce957
# ╠═10cd61db-09b9-4876-a3c9-2114578da639
# ╟─a1aa126f-15f3-44a2-8acb-ebccd8f16cfd
# ╠═9c002ca1-28ac-451c-ada2-8e55b90d3e64
# ╟─6154997e-a121-430e-bafe-c794412d9478
# ╠═2ae4588f-6b88-47b0-928a-36e6df4bd755
# ╟─201c7fd9-5723-46ce-84fa-7cb400a02f7b
# ╠═766d92dd-3df7-43f5-853c-43c4194aa842
# ╟─c7a414ca-a016-4959-8e06-080907ff244c
# ╠═382f7095-a3fe-4e99-9a2f-1b745f41830f
# ╟─e19c3b51-8405-4c47-9e7d-df809d281b9b
# ╠═d18227df-56d5-4879-ac26-9f45d35ba144
# ╟─4537e253-4954-4d2c-bc33-18aee3a2bdf5
# ╠═301a8694-0b01-4515-ab40-d0f8564cfc78
# ╟─749bf936-eefc-4dd5-b495-939d82f496a0
# ╟─0571129d-bdbf-4ff4-b607-dacb6d6d3911
