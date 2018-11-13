# [Automatic Differentiation](@id autodiff)

## Classical back propagation
Back propagation has $O(M)$ complexity in obtaining gradients, with $M$ the number of circuit parameters.
We can use `autodiff(:BP)` to mark differentiable units in a circuit. Let's see an example.

### Example: Classical back propagation
```@repl Diff
using Yao
circuit = chain(4, repeat(4, H, 1:4), put(4, 3=>Rz(0.5)), control(2, 1=>X), put(4, 4=>Ry(0.2)))
circuit = circuit |> autodiff(:BP)
```
From the output, we can see parameters of blocks marked by `[∂]` will be differentiated automatically.

```@repl Diff
op = put(4, 3=>Y);  # loss is defined as its expectation.
ψ = rand_state(4);
ψ |> circuit;
δ = ψ |> op;     # ∂f/∂ψ*
backward!(δ, circuit);    # classical back propagation!
```
Here, the loss is `L = <ψ|op|ψ>`, `δ = ∂f/∂ψ*` is the error to be back propagated.
The gradient is related to $δ$ as
$$\frac{\partial f}{\partial\theta} = 2\Re[\frac{\partial f}{\partial\psi^*}\frac{\partial \psi^*}{\partial\theta}]$$

In face, `backward!(δ, circuit)` on wave function is equivalent to calculating `δ |> circuit'` (`apply!(reg, Daggered{<:BPDiff})`).
This function is overloaded so that gradientis for parameters are also calculated and stored in [`BPDiff`](@ref) block at the same time.

Finally, we use `gradient` to collect gradients in the ciruits.
```@repl Diff
g1 = gradient(circuit)  # collect gradient
```

!!! note

    In real quantum devices, gradients can not be back propagated, this is why we need the following section.

## Quantum circuit differentiation

Experimental applicable differentiation strategies are based on the following two papers

* [Quantum Circuit Learning](https://arxiv.org/abs/1803.00745), Kosuke Mitarai, Makoto Negoro, Masahiro Kitagawa, Keisuke Fujii
* [Differentiable Learning of Quantum Circuit Born Machine](https://arxiv.org/abs/1804.04168), Jin-Guo Liu, Lei Wang

The former differentiation scheme is for observables, and the latter is for statistic functionals (U statistics).
One may find the derivation of both schemes in [this post](https://giggleliu.github.io/2018/04/16/circuitgrad.html).

Realizable quantum circuit gradient finding algorithms have complexity $O(M^2)$.

### Example: Practical quantum differenciation
We use [`QDiff`](@ref) block to mark differentiable circuits
```@repl QDiff
using Yao, Yao.Blocks
c = chain(put(4, 1=>Rx(0.5)), control(4, 1, 2=>Ry(0.5)), kron(4, 2=>Rz(0.3), 3=>Rx(0.7))) |> autodiff(:QC)  # automatically mark differentiable blocks
```
Blocks marked by `[̂∂]` will be differentiated.

```@repl QDiff
dbs = collect(c, QDiff)  # collect all QDiff blocks
```
Here, we recommend collect [`QDiff`](@ref) blocks into a sequence using `collect` API for future calculations.
Then, we can get the gradient one by one, using `opdiff`
```@repl QDiff
ed = opdiff(dbs[1], put(4, 1=>Z)) do   # the exact differentiation with respect to first QDiff block.
    zero_state(4) |> c
end
```
Here, contents in the do-block returns the loss, it must be the expectation value of an observable.

For results checking, we get the numeric gradient use `numdiff`
```@repl QDiff
ed = numdiff(dbs[1]) do    # compare with numerical differentiation
   expect(put(4, 1=>Z), zero_state(4) |> c) |> real
end
```
This numerical differentiation scheme is always applicable (even the loss is not an observable), but with numeric errors introduced by finite step size.

We can also get all gradients using broadcasting
```@repl QDiff
ed = opdiff.(()->zero_state(4) |> c, dbs, Ref(kron(4, 1=>Z, 2=>X)))   # using broadcast to get all gradients.
```

!!! note

    Since BP is not implemented for `QDiff` blocks, the memory consumption is much less since we don't cache intermediate results anymore.
