
# [Quantum Circuit Born Machine](@id qcbm)

Yao is designed with variational quantum circuits in mind, and this tutorial
will introduce how to use Yao for this kind of task by implementing a quantum
circuit born machine described in [Jin-Guo Liu, Lei Wang (2018)](https://arxiv.org/abs/1804.04168)

let's use the package first

````julia
using Yao, LinearAlgebra
````





## Training Target

In this tutorial, we will ask the variational circuit to learn the most basic
distribution: a guassian distribution. It is defined as follows:

```math
f(x \left| \mu, \sigma^2\right) = \frac{1}{\sqrt{2\pi\sigma^2}} e^{-\frac{(x-\mu)^2}{2\sigma^2}}
```

We implement it as `gaussian_pdf`:

````julia
function gaussian_pdf(x, μ::Real, σ::Real)
    pl = @. 1 / sqrt(2pi * σ^2) * exp(-(x - μ)^2 / (2 * σ^2))
    pl / sum(pl)
end
pg = gaussian_pdf(1:1<<6, 1<<5-0.5, 1<<4);
````





We can plot the distribution, it looks like

![Gaussian Distribution](../assets/figures/QCBM_1.svg)

## Create the Circuit

A quantum circuit born machine looks like the following:

![differentiable ciruit](../assets/figures/differentiable.png)

It is composited by two different layers: **rotation layer** and **entangler layer**.

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
ncludes all **quantum gates** and **quantum oracles**.
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

````julia
chain(Rz(0.0), Rx(0.0), Rz(0.0))
````


````
nqubits: 1
chain
├─ rot(Z gate, 0.0)
├─ rot(X gate, 0.0)
└─ rot(Z gate, 0.0)
````





[`Rx`](@ref), [`Rz`](@ref) will construct new rotation gate,
which are just shorthands for `rot(X, 0.0)`, etc.

Then let's chain them up

````julia
layer(nbit::Int, x::Symbol) = layer(nbit, Val(x))
layer(nbit::Int, ::Val{:first}) = chain(nbit, put(i=>chain(Rx(0), Rz(0))) for i = 1:nbit);
````





We do not need to feed the first `n` parameter into `put` here.
All factory methods can be **lazy** evaluate **the first arguements**, which is the number of qubits.
It will return a lambda function that requires a single interger input.
The instance of desired block will only be constructed until all the information is filled.
When you filled all the information in somewhere of the declaration, 幺 will be able to infer the others.
We will now define the rest of rotation layers

````julia
layer(nbit::Int, ::Val{:last}) = chain(nbit, put(i=>chain(Rz(0), Rx(0))) for i = 1:nbit)
layer(nbit::Int, ::Val{:mid}) = chain(nbit, put(i=>chain(Rz(0), Rx(0), Rz(0))) for i = 1:nbit);
````





## Entangler

Another component of quantum circuit born machine are
several **CNOT** operators applied on different qubits.

````julia
entangler(pairs) = chain(control(ctrl, target=>X) for (ctrl, target) in pairs);
````





We can then define such a born machine

````julia
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
````


````
build_circuit (generic function with 1 method)
````





We use the method `cache` here to tag the entangler block that it
should be cached after its first run, because it is actually a
constant oracle. Let's see what will be constructed

````julia
build_circuit(4, 1, [1=>2, 2=>3, 3=>4])
````


````
nqubits: 4
chain
├─ chain
│  ├─ put on (1)
│  │  └─ chain
│  │     ├─ rot(X gate, 0.0)
│  │     └─ rot(Z gate, 0.0)
│  ├─ put on (2)
│  │  └─ chain
│  │     ├─ rot(X gate, 0.0)
│  │     └─ rot(Z gate, 0.0)
│  ├─ put on (3)
│  │  └─ chain
│  │     ├─ rot(X gate, 0.0)
│  │     └─ rot(Z gate, 0.0)
│  └─ put on (4)
│     └─ chain
│        ├─ rot(X gate, 0.0)
│        └─ rot(Z gate, 0.0)
├─ [cached] chain
│     ├─ control(1)
│     │  └─ (2,) X gate
│     ├─ control(2)
│     │  └─ (3,) X gate
│     └─ control(3)
│        └─ (4,) X gate
└─ chain
   ├─ put on (1)
   │  └─ chain
   │     ├─ rot(Z gate, 0.0)
   │     └─ rot(X gate, 0.0)
   ├─ put on (2)
   │  └─ chain
   │     ├─ rot(Z gate, 0.0)
   │     └─ rot(X gate, 0.0)
   ├─ put on (3)
   │  └─ chain
   │     ├─ rot(Z gate, 0.0)
   │     └─ rot(X gate, 0.0)
   └─ put on (4)
      └─ chain
         ├─ rot(Z gate, 0.0)
         └─ rot(X gate, 0.0)
````





## MMD Loss & Gradients

The MMD loss is describe below:

```math
\begin{aligned}
\mathcal{L} &= \left| \sum_{x} p \theta(x) \phi(x) - \sum_{x} \pi(x) \phi(x) \right|^2\\
            &= \langle K(x, y) \rangle_{x \sim p_{\theta}, y\sim p_{\theta}} - 2 \langle K(x, y) \rangle_{x\sim p_{\theta}, y\sim \pi} + \langle K(x, y) \rangle_{x\sim\pi, y\sim\pi}
\end{aligned}
```


We will use a squared exponential kernel here.


````julia
struct RBFKernel
    σ::Float64
    m::Matrix{Float64}
end

function RBFKernel(σ::Float64, space)
    dx2 = (space .- space').^2
    return RBFKernel(σ, exp.(-1/2σ * dx2))
end

kexpect(κ::RBFKernel, x, y) = x' * κ.m * y
````


````
kexpect (generic function with 1 method)
````





There are two different way to define the loss:

In simulation we can use the probability distribution of the state directly

````julia
get_prob(qcbm) = probs(zero_state(nqubits(qcbm)) |> qcbm)

function loss(κ, c, target)
    p = get_prob(c) - target
    return kexpect(κ, p, p)
end
````


````
loss (generic function with 1 method)
````





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

````julia
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
````


````
gradient (generic function with 1 method)
````





Now let's setup the training

````julia
using Flux.Optimise
qcbm = build_circuit(6, 10, [1=>2, 3=>4, 5=>6, 2=>3, 4=>5, 6=>1])
dispatch!(qcbm, :random) # initialize the parameters

κ = RBFKernel(0.25, 0:2^6-1)
pg = gaussian_pdf(1:1<<6, 1<<5-0.5, 1<<4);
opt = ADAM()

function train(qcbm, κ, opt, target)
    history = Float64[]
    for _ in 1:100
        push!(history, loss(κ, qcbm, target))
        ps = parameters(qcbm)
        Optimise.update!(opt, ps, gradient(qcbm, κ, target))
        popdispatch!(qcbm, ps)
    end
    return history
end

history = train(qcbm, κ, opt, pg)
trained_pg = probs(zero_state(nqubits(qcbm)) |> qcbm)
history
````


````
100-element Array{Float64,1}:
 0.024567277267828147 
 0.02409434288356567  
 0.02362743420420131  
 0.023166429304917108 
 0.022711226202297638 
 0.022262114064746045 
 0.02181904425594547  
 0.021381887012790514 
 0.02095065811724848  
 0.0205254192477336   
 ⋮                    
 0.0024442488584926654
 0.002358203844023304 
 0.002274410467147896 
 0.002193109378880525 
 0.002114120861527462 
 0.0020377079142356353
 0.0019637499488247287
 0.0018920452544216127
 0.0018226967981342522
````





And we have the history of training which is

````julia

using Plots
fig1 = plot(history; legend=nothing)
title!("training history")
xlabel!("steps"); ylabel!("loss")
````




![](../assets/figures/history.png)

And let's check what we got

````julia

fig2 = plot(1:1<<6, trained_pg; label="trained")
plot!(fig2, 1:1<<6, pg; label="target")
title!("distribution")
xlabel!("x"); ylabel!("p")
````




![](../assets/figures/distribution.png)

So within 50 steps, we got a pretty close estimation of our
target distribution!
