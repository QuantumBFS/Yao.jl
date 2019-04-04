# Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit

First, you have to use this package in Julia.

````julia
using Yao
````





Now, we just define this the circuit according to the circuit image below:

![ghz](../assets/figures/ghz4.png)

````julia
circuit(n) = chain(
    n,
    repeat(X, (1,)),
    kron(i=>H for i in 2:n),
    control([2, ], 1=>X),
    control([4, ], 3=>X),
    control([3, ], 1=>X),
    control([4, ], 3=>X),
    kron(i=>H for i in 1:n),
)
````


````
circuit (generic function with 1 method)
````


