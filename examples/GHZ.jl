using Yao

circuit(n) = chain(
    n,
    kron(i=>H for i in 1:n),
    control([4, ], 3=>X),
    control([3, ], 1=>X),
    control([4, ], 3=>X),
    control([2, ], 1=>X),
    kron(i=>H for i in 2:n),
    repeat(1=>X),
)

rand_state(4)
