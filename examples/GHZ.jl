using Yao

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

println("GHZ state = ", apply!(zero_state(4), circuit(4)) |> statevec)
