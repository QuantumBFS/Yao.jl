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
end

# ╔═╡ a49017b7-64b9-4519-9a91-457f2a303e1c
using Yao, YaoPlots

# ╔═╡ a120d2b5-e408-466e-9394-33e377f90de1
using Plots, LinearAlgebra

# ╔═╡ c788534a-ee16-4972-91ce-b0b3ed2799fa
md"""
# Quick Start Guide

This guide is for people who:

- doesn't know much Julia but knows Python (or other programming languages)
- knows quantum computing basics
- want to try out programming quantum circuits quickly with Julia

the contents are organized as following

1. Julia Basics
2. Basic Concepts of Yao
3. How to write a Quantum Circuit Born Machine using Yao
"""

# ╔═╡ 01ebf798-c068-4115-9cb9-381f5d8e8b35
md"""
## Julia Basics

You can jump to next section if you already know how to use Julia. We will only be introduce some basic concepts of Julia and differences comparing to Python in this section, if you wish to learn this language more seriously please refer to the learning materials on the official website: [julialang.org/learning/](https://julialang.org/learning/). This short Julia tutorial is based on [MIT computational thinking course](https://computationalthinking.mit.edu/).

If you haven't installed Julia, please refer to the front page of Julia: [julialang.org](https://julialang.org/)

If you wish to run this notebook locally, you will need to install [Pluto](https://github.com/fonsp/Pluto.jl):

1. open your [Julia interactive session (known as REPL)](https://docs.julialang.org/en/v1/manual/getting-started/)
2. press `]` key in the REPL to use the package mode, then type the following command

```julia
pkg> add Pluto
```

you will now see Julia's package manager start downloading this package. After the download is finished, press `backspace` and run the following command.

```julia
julia> import Pluto

julia> Pluto.run()
```

now it should open a web page for you in the browser, choose the downloaded notebook file `quick-start.jl`, you are good to go!
"""

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

All Julia program **runs inside an environment**, it is the global environment by default. It is usually recommended to run your notebook in a local environment, so we won't hit **any version conflicts** between different packages. You can create and activate a new temperary environment and install Yao as following:
"""

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

# ╔═╡ b6cafdc0-e778-44e7-94af-01d60fef2f09
zero_state(5)

# ╔═╡ 2afa7e59-1974-42f8-8399-2fd8b7680536
r = rand_state(5)

# ╔═╡ ce9eea0e-7ae7-4e5d-a3a5-db658df5a797
md"you can measure the register using `measure`"

# ╔═╡ b1a009d1-b098-4b8a-9f77-c0a56fe9f309
measure(r; nshots=5)

# ╔═╡ eaa99d2c-c96d-4034-ba98-96585c46c15f
md"""
or a convenient function `expect` is provided to calcualte the expectation on a given operator
"""

# ╔═╡ 563acff1-3bf9-4808-b202-e0fd6b5f18c9
expect(sum(put(5, i=>X) for i in 1:5), r)

# ╔═╡ 62a8531d-2eb8-4a07-84ae-75c130b56b7b
md"here we use `kron` to construct a simple 5-site Hamiltonian ``\sum_{i=1}^5 X_i``:"

# ╔═╡ 5cffa9e8-fcdd-4500-9d48-62339a2857ed
hamiltonian = sum(put(5, i=>X) for i in 1:5)

# ╔═╡ 48e8742b-0c07-443e-845e-4b4883fc659f
md"now if we define a simple parameterized circuit using ``R_x(θ)``"

# ╔═╡ ceac3d5e-93ef-419d-80e7-af69b2e94864
circuit(θ) = chain(5, put(3=>Rx(θ)))

# ╔═╡ 663cdd78-6204-4307-98d2-7037723c6f24
md"we can use the following syntax to calculate the expectation:"

# ╔═╡ 987f381d-32b1-4b21-a80d-b633772b1a4b
expect(hamiltonian, r=>circuit(2.0))

# ╔═╡ fddc9185-6a54-49b1-888d-f4c5f227e065
md"and the gradient of θ:"

# ╔═╡ 64bbde8f-3d50-4bfe-8972-985ad083dba2
expect'(hamiltonian, r=>circuit(2.0))

# ╔═╡ 803052be-4c40-443d-b8fa-8c3398ae8094
md"""
## Implementing Quantum Circuit Born Machine

Yao is designed with variational quantum circuits in mind, and this section, we
will introduce how to use Yao for this kind of task by implementing a quantum
circuit born machine described in [Jin-Guo Liu, Lei Wang (2018)](https://arxiv.org/abs/1804.04168)

first we install one more package for plotting:
"""

# ╔═╡ db7c91af-1621-4d79-a61c-2ff7b86db491
Pkg.add("Plots")

# ╔═╡ 3b7ba2a8-8759-4ab1-adc1-1a77c389fb41
md"""
## Training Target

In this tutorial, we will ask the variational circuit to learn the most basic
distribution: a guassian distribution. It is defined as follows:

```math
f(x \left| \mu, \sigma^2\right) = \frac{1}{\sqrt{2\pi\sigma^2}} e^{-\frac{(x-\mu)^2}{2\sigma^2}}
```

We implement it as `gaussian_pdf`:

"""

# ╔═╡ d3869fc6-4a69-4d11-8e03-0d3b6a224e75
function gaussian_pdf(x, μ::Real, σ::Real)
    pl = @. 1 / sqrt(2pi * σ^2) * exp(-(x - μ)^2 / (2 * σ^2))
    pl / sum(pl)
end

# ╔═╡ 6d5dc55e-4ada-4a90-8522-f0c270cd3f42
pg = gaussian_pdf(1:1<<6, 1<<5-0.5, 1<<4)

# ╔═╡ c122f2b6-72ef-4cc8-b14f-0d26160c7fea
md"We can plot the distribution, it looks like"

# ╔═╡ 7b42ad5d-0350-4b86-8a67-7fc041d9eff5
Plots.plot(pg)

# ╔═╡ ed4c3900-cd72-4012-9279-5e806d7325cb
md"""
## Create the Circuit
A quantum circuit born machine is composited by two different layers: **rotation layer** and **entangler layer**.

## Rotation Layer

Arbitrary rotation is built with **Rotation Gate** on **Z, X, Z** axis
with parameters.

```math
Rz(\theta) \cdot Rx(\theta) \cdot Rz(\theta)
```

Since our input will be a ``|0\dots 0\rangle`` state.
The first layer of arbitrary rotation can just
use ``Rx(\theta) \cdot Rz(\theta)`` and the last
layer of arbitrary rotation could just
use ``Rz(\theta)\cdot Rx(\theta)``

In **幺**, every Hilbert operator is a **block** type, this
includes all **quantum gates** and **quantum oracles**.
In general, operators appears in a quantum circuit
can be divided into **Composite Blocks** and **Primitive Blocks**.

We follow the low abstraction principle and
thus each block represents a certain approach
of calculation. The simplest **Composite Block**
is a **Chain Block**, which chains other blocks
(oracles) with the same number of qubits together.
It is just a simple mathematical composition of
operators with same size. e.g.


```math
\text{chain(X, Y, Z)} \iff X \cdot Y \cdot Z
```

We can construct an arbitrary rotation block by chain ``Rz``, ``Rx``, ``Rz`` together.
"""

# ╔═╡ 103d36e0-f3b8-4f1e-9a0d-aeabb83818d1
YaoPlots.plot(chain(Rz(0.0), Rx(0.0), Rz(0.0)))

# ╔═╡ 4d151c49-34a8-4eea-b6b2-edb9991d5fbc
md"""
`Rx`, `Rz` will construct new rotation gate,
which are just shorthands for `rot(X, 0.0)`, etc.

Then let's chain them up
"""

# ╔═╡ d78eeaf9-f110-41f1-82e3-b7f2ba84f098
layer(nbit::Int, x::Symbol) = layer(nbit, Val(x))

# ╔═╡ 45be3e84-db17-462d-92c5-ad0d7ae0294b
layer(nbit::Int, ::Val{:first}) = chain(nbit, put(i=>chain(Rx(0), Rz(0))) for i = 1:nbit)

# ╔═╡ 8e54478a-d207-40fb-a5d0-91136dd06f1e
md"""
We do not need to feed the first `n` parameter into `put` here.
All factory methods can be **lazy** evaluate **the first arguements**, which is the number of qubits.
It will return a lambda function that requires a single interger input.
The instance of desired block will only be constructed until all the information is filled.
When you filled all the information in somewhere of the declaration, 幺 will be able to infer the others.
We will now define the rest of rotation layers
"""

# ╔═╡ 2eb04052-86e8-4d09-9e70-1bfe77923085
layer(nbit::Int, ::Val{:last}) = chain(nbit, put(i=>chain(Rz(0), Rx(0))) for i = 1:nbit)

# ╔═╡ 86eda4a1-8f18-4412-bd61-6d64c150e82b
layer(nbit::Int, ::Val{:mid}) = chain(nbit, put(i=>chain(Rz(0), Rx(0), Rz(0))) for i = 1:nbit)

# ╔═╡ 68ad1aee-9517-4a08-8a64-6d981efd29c8
md"""
## Entangler

Another component of quantum circuit born machine are
several **CNOT** operators applied on different qubits.
"""

# ╔═╡ 714b624d-9d5c-46db-a4a9-71be7564bcdc
entangler(pairs) = chain(control(ctrl, target=>X) for (ctrl, target) in pairs)

# ╔═╡ 6c03277b-185f-4c6c-a88c-d4651b085a5a
YaoPlots.plot(entangler([1=>2, 3=>4])(5))

# ╔═╡ 777ef904-e44f-419e-96fd-b6f893dd8f8a
md"We can then define such a born machine"

# ╔═╡ e6a9ee42-719d-4181-be56-eecd9464057c
function build_circuit(n, nlayers, pairs)
    circuit = chain(n)
    push!(circuit, layer(n, :first))
    for i in 2:nlayers
        push!(circuit, cache(entangler(pairs)))
        push!(circuit, layer(n, :mid))
    end
    push!(circuit, cache(entangler(pairs)))
    push!(circuit, layer(n, :last))
    return circuit
end

# ╔═╡ 691d6352-9766-4a15-b442-04237f9e1ee0
YaoPlots.plot(build_circuit(5, 3, [1=>2, 2=>3, 3=>4, 4=>5, 5=>1]))

# ╔═╡ 25253e3b-c087-45d8-8583-3b399e43fdee
md"""
We use the method `cache` here to tag the entangler block that it
should be cached after its first run, because it is actually a
constant oracle. Let's see what will be constructed
"""

# ╔═╡ 24d3a673-c9bc-4e8e-adfd-27988b2a5b8a
md"""
## MMD Loss & Gradients

The MMD loss is describe below:

```math
\begin{aligned}
\mathcal{L} &= \left| \sum_{x} p \theta(x) \phi(x) - \sum_{x} \pi(x) \phi(x) \right|^2\\
            &= \langle K(x, y) \rangle_{x \sim p_{\theta}, y\sim p_{\theta}} - 2 \langle K(x, y) \rangle_{x\sim p_{\theta}, y\sim \pi} + \langle K(x, y) \rangle_{x\sim\pi, y\sim\pi}
\end{aligned}
```

We will use a squared exponential kernel here.
"""

# ╔═╡ cfa937f1-c861-4dc9-ad9a-7d16b60f0c04
begin
	struct RBFKernel
	    σ::Float64
	    m::Matrix{Float64}
	end
	
	function RBFKernel(σ::Float64, space)
	    dx2 = (space .- space').^2
	    return RBFKernel(σ, exp.(-1/2σ * dx2))
	end
	
	kexpect(κ::RBFKernel, x, y) = x' * κ.m * y
end

# ╔═╡ 43bc5e0f-083b-432f-ad20-0b0024fce80a
md"""
There are two different way to define the loss:

In simulation we can use the probability distribution of the state directly
"""

# ╔═╡ 47bfb83f-7b5c-4aee-9ecc-99c836143540
get_prob(qcbm) = probs(zero_state(nqubits(qcbm)) |> qcbm)

# ╔═╡ 52f516ef-07f5-4eb4-9a50-fc5c55a8378b
function loss(κ, c, target)
    p = get_prob(c) - target
    return kexpect(κ, p, p)
end

# ╔═╡ 8a684763-10e5-4206-9e64-83567ad909da
md"""
Or if you want to simulate the whole process with measurement (which is entirely
physical), you should define the loss with measurement results, for convenience
we directly use the simulated results as our loss

### Gradients

the gradient of MMD loss is

```math
\begin{aligned}
\frac{\partial \mathcal{L}}{\partial \theta^i_l} &= \langle K(x, y) \rangle_{x\sim p_{\theta^+}, y\sim p_{\theta}} - \langle K(x, y) \rangle_{x\sim p_{\theta}^-, y\sim p_{\theta}}\\
&- \langle K(x, y) \rangle _{x\sim p_{\theta^+}, y\sim\pi} + \langle K(x, y) \rangle_{x\sim p_{\theta^-}, y\sim\pi}
\end{aligned}
```

which can be implemented as
"""

# ╔═╡ 8e06a6e1-3fbf-42b5-ad48-123d89fa543b
function gradient(qcbm, κ, ptrain)
    n = nqubits(qcbm)
    prob = get_prob(qcbm)
    grad = zeros(Float64, nparameters(qcbm))

    count = 1
    for k in 1:2:length(qcbm), each_line in qcbm[k], gate in content(each_line)
        dispatch!(+, gate, π/2)
        prob_pos = probs(zero_state(n) |> qcbm)

        dispatch!(-, gate, π)
        prob_neg = probs(zero_state(n) |> qcbm)

        dispatch!(+, gate, π/2) # set back

        grad_pos = kexpect(κ, prob, prob_pos) - kexpect(κ, prob, prob_neg)
        grad_neg = kexpect(κ, ptrain, prob_pos) - kexpect(κ, ptrain, prob_neg)
        grad[count] = grad_pos - grad_neg
        count += 1
    end
    return grad
end

# ╔═╡ 43a17b19-16c3-4637-bcad-47bf0c562251
md"Now let's setup the training, we will use the ADAM optimizer from our [quantum algorithm zoo](https://github.com/QuantumBFS/QuAlgorithmZoo.jl)"

# ╔═╡ b7b56dd6-0b23-44fe-b1d3-487383986975
Pkg.add(url="https://github.com/QuantumBFS/QuAlgorithmZoo.jl.git")

# ╔═╡ 427e33d9-d399-4e5d-9622-431e1fbd2b07
import QuAlgorithmZoo

# ╔═╡ 0a80c152-1b02-44b2-b5a1-89b93e5239c6
qcbm = build_circuit(6, 10, [1=>2, 3=>4, 5=>6, 2=>3, 4=>5, 6=>1])

# ╔═╡ f7cfa8d9-7695-4ad8-930d-cf242059b400
YaoPlots.plot(dispatch!(qcbm, :random)) # initialize the parameters

# ╔═╡ 4dba452c-ef69-40ce-bd8f-c8a8b189a0a8
begin
	κ = RBFKernel(0.25, 0:2^6-1)
	opt = QuAlgorithmZoo.Adam(lr=0.01)
end

# ╔═╡ d01425cb-336b-4729-9ef0-7a83fea32f99
function train(qcbm, κ, opt, target)
    history = Float64[]
    for _ in 1:100
        push!(history, loss(κ, qcbm, target))
        ps = parameters(qcbm)
        QuAlgorithmZoo.update!(ps, gradient(qcbm, κ, target), opt)
        dispatch!(qcbm, ps)
    end
    return history
end

# ╔═╡ b03bfe4b-f71e-493e-8f7f-886f4ba8b3b6
history = train(qcbm, κ, opt, pg)

# ╔═╡ ee0f95f9-2800-4f45-b380-c19a1a32464e
md"""
we can see we "learn" this simple gausian distribution!
"""

# ╔═╡ a2d494f6-833b-44d9-80c1-0fc6a64c1e0b
trained_pg = probs(zero_state(nqubits(qcbm)) |> qcbm)

# ╔═╡ 883125f1-633d-43fc-8f07-e21b6c4b50cb
begin
	fig2 = Plots.plot(1:1<<6, trained_pg; label="trained")
	Plots.plot!(fig2, 1:1<<6, pg; label="target")
	title!("distribution")
	xlabel!("x"); ylabel!("p")
	fig2
end

# ╔═╡ d8faaef1-fbf0-432b-a9a1-33c91a963dcf
md"now let's plot the training history"

# ╔═╡ 5a5963c0-5270-469d-b3f5-b83fa1422bde
Plots.plot(history)

# ╔═╡ Cell order:
# ╟─c788534a-ee16-4972-91ce-b0b3ed2799fa
# ╟─01ebf798-c068-4115-9cb9-381f5d8e8b35
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
# ╠═b6cafdc0-e778-44e7-94af-01d60fef2f09
# ╠═2afa7e59-1974-42f8-8399-2fd8b7680536
# ╟─ce9eea0e-7ae7-4e5d-a3a5-db658df5a797
# ╠═b1a009d1-b098-4b8a-9f77-c0a56fe9f309
# ╟─eaa99d2c-c96d-4034-ba98-96585c46c15f
# ╠═563acff1-3bf9-4808-b202-e0fd6b5f18c9
# ╟─62a8531d-2eb8-4a07-84ae-75c130b56b7b
# ╠═5cffa9e8-fcdd-4500-9d48-62339a2857ed
# ╟─48e8742b-0c07-443e-845e-4b4883fc659f
# ╠═ceac3d5e-93ef-419d-80e7-af69b2e94864
# ╟─663cdd78-6204-4307-98d2-7037723c6f24
# ╠═987f381d-32b1-4b21-a80d-b633772b1a4b
# ╟─fddc9185-6a54-49b1-888d-f4c5f227e065
# ╠═64bbde8f-3d50-4bfe-8972-985ad083dba2
# ╟─803052be-4c40-443d-b8fa-8c3398ae8094
# ╠═db7c91af-1621-4d79-a61c-2ff7b86db491
# ╠═a120d2b5-e408-466e-9394-33e377f90de1
# ╟─3b7ba2a8-8759-4ab1-adc1-1a77c389fb41
# ╠═d3869fc6-4a69-4d11-8e03-0d3b6a224e75
# ╠═6d5dc55e-4ada-4a90-8522-f0c270cd3f42
# ╟─c122f2b6-72ef-4cc8-b14f-0d26160c7fea
# ╠═7b42ad5d-0350-4b86-8a67-7fc041d9eff5
# ╟─ed4c3900-cd72-4012-9279-5e806d7325cb
# ╠═103d36e0-f3b8-4f1e-9a0d-aeabb83818d1
# ╟─4d151c49-34a8-4eea-b6b2-edb9991d5fbc
# ╠═d78eeaf9-f110-41f1-82e3-b7f2ba84f098
# ╠═45be3e84-db17-462d-92c5-ad0d7ae0294b
# ╟─8e54478a-d207-40fb-a5d0-91136dd06f1e
# ╠═2eb04052-86e8-4d09-9e70-1bfe77923085
# ╠═86eda4a1-8f18-4412-bd61-6d64c150e82b
# ╟─68ad1aee-9517-4a08-8a64-6d981efd29c8
# ╠═714b624d-9d5c-46db-a4a9-71be7564bcdc
# ╠═6c03277b-185f-4c6c-a88c-d4651b085a5a
# ╟─777ef904-e44f-419e-96fd-b6f893dd8f8a
# ╠═e6a9ee42-719d-4181-be56-eecd9464057c
# ╠═691d6352-9766-4a15-b442-04237f9e1ee0
# ╟─25253e3b-c087-45d8-8583-3b399e43fdee
# ╟─24d3a673-c9bc-4e8e-adfd-27988b2a5b8a
# ╠═cfa937f1-c861-4dc9-ad9a-7d16b60f0c04
# ╟─43bc5e0f-083b-432f-ad20-0b0024fce80a
# ╠═47bfb83f-7b5c-4aee-9ecc-99c836143540
# ╠═52f516ef-07f5-4eb4-9a50-fc5c55a8378b
# ╠═8a684763-10e5-4206-9e64-83567ad909da
# ╠═8e06a6e1-3fbf-42b5-ad48-123d89fa543b
# ╟─43a17b19-16c3-4637-bcad-47bf0c562251
# ╠═b7b56dd6-0b23-44fe-b1d3-487383986975
# ╠═427e33d9-d399-4e5d-9622-431e1fbd2b07
# ╠═0a80c152-1b02-44b2-b5a1-89b93e5239c6
# ╠═f7cfa8d9-7695-4ad8-930d-cf242059b400
# ╠═4dba452c-ef69-40ce-bd8f-c8a8b189a0a8
# ╠═d01425cb-336b-4729-9ef0-7a83fea32f99
# ╠═b03bfe4b-f71e-493e-8f7f-886f4ba8b3b6
# ╠═ee0f95f9-2800-4f45-b380-c19a1a32464e
# ╠═a2d494f6-833b-44d9-80c1-0fc6a64c1e0b
# ╠═883125f1-633d-43fc-8f07-e21b6c4b50cb
# ╠═d8faaef1-fbf0-432b-a9a1-33c91a963dcf
# ╠═5a5963c0-5270-469d-b3f5-b83fa1422bde
