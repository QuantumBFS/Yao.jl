export hadamard_test, hadamard_test_circuit, swap_test_circuit

"""
    hadamard_test_circuit(U::AbstractBlock, ϕ::Real)

The Hadamard test circuit.

References
-----------------------
* [Wiki](https://en.wikipedia.org/wiki/Hadamard_test_(quantum_computation))
"""
function hadamard_test_circuit(U::AbstractBlock{N}, ϕ::Real) where N
    chain(N+1, put(N+1, 1=>H),
        put(N+1, 1=>Rz(ϕ)),
        control(N+1, 1, 2:N+1=>U),  # get matrix first, very inefficient
        put(N+1, 1=>H)
        )
end

function hadamard_test(U::AbstractBlock{N}, reg::AbstractRegister, ϕ::Real) where N
    c = hadamard_test_circuit(U, ϕ::Real)
    reg = join(reg, zero_state(1))
    expect(put(N+1, 1=>Z), reg |> c)
end

"""
    swap_test_circuit(nbit::Int, nstate::Int, ϕ::Real)

The swap test circuit for computing the overlap between multiple density matrices.
The `nbit` and `nstate` specifies the number of qubit in each state and how many state we want to compare.

References
-----------------------
* Ekert, Artur K., et al. "Direct estimations of linear and nonlinear functionals of a quantum state." Physical review letters 88.21 (2002): 217901.
"""
function swap_test_circuit(nbit::Int, nstate::Int, ϕ::Real)
    N = nstate*nbit + 1

    chain(N, put(N, 1=>H),
        put(N, 1=>Rz(ϕ)),
        chain(N, [chain(N, [control(N, 1, (i+(k*nbit-nbit)+1, i+k*nbit+1)=>SWAP) for i=1:nbit]) for k=1:nstate-1]),  # get matrix first, very inefficient
        put(N, 1=>H)
        )
end