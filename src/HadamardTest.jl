export hadamard_test, hadamard_test_circuit, swap_test_circuit

"""
see WiKi.
"""
function hadamard_test_circuit(U::MatrixBlock{N}, ϕ::Real) where N
    chain(N+1, put(N+1, 1=>H),
        put(N+1, 1=>Rz(ϕ)),
        control(N+1, 1, 2:N+1=>U),  # get matrix first, very inefficient
        put(N+1, 1=>H)
        )
end

function hadamard_test(U::MatrixBlock{N}, reg::AbstractRegister, ϕ::Real) where N
    c = hadamard_test_circuit(U, ϕ::Real)
    reg = join(reg, zero_state(1))
    expect(put(N+1, 1=>Z), reg |> c)
end

"""
Estimation of overlap between multiple density matrices.

PRL 88.217901
"""
function swap_test_circuit(nbit::Int, nstate::Int, ϕ::Real)
    N = nstate*nbit + 1

    chain(N, put(N, 1=>H),
        put(N, 1=>Rz(ϕ)),
        chain(N, [chain(N, [control(N, 1, (i+(k*nbit-nbit)+1, i+k*nbit+1)=>SWAP) for i=1:nbit]) for k=1:nstate-1]),  # get matrix first, very inefficient
        put(N, 1=>H)
        )
end
