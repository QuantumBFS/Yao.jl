export hadamard_test, hadamard_test_circuit, swap_test, swap_test_circuit, singlet_block, state_overlap_circuit

"""
see WiKi.
"""
function hadamard_test_circuit(U::MatrixBlock{N}) where N
    chain(N+1, put(N+1, 1=>H),
        control(N+1, 1, 2:N+1=>U),  # get matrix first, very inefficient
        put(N+1, 1=>H)
        )
end

function hadamard_test(U::MatrixBlock{N}, reg::AbstractRegister) where N
    c = hadamard_test_circuit(U)
    reg = join(reg, zero_state(1))
    expect(put(N+1, 1=>Z), reg |> c)
end

swap_test_circuit() = hadamard_test_circuit(SWAP)
swap_test(reg::AbstractRegister) = hadamard_test(SWAP, reg)

function singlet_block(::Type{T}, nbit::Int, i::Int, j::Int) where T
    unit = chain(nbit)
    push!(unit, put(nbit, i=>chain(XGate{T}(), HGate{T}())))
    push!(unit, control(nbit, -i, j=>XGate{T}()))
end

singlet_block(nbit::Int, i::Int, j::Int) = singlet_block(ComplexF64, nbit, i, j)
singlet_block() = singlet_block(2,1,2)

"""
Estimation of overlap between multiple density matrices.

PRL 88.217901
"""
function state_overlap_circuit(nbit::Int, nstate::Int, ϕ::Real)
    N = nstate*nbit + 1

    chain(N, put(N, 1=>H),
        put(N, 1=>shift(ϕ)),
        chain(N, [chain(N, [control(N, 1, (i+(k*nbit-nbit)+1, i+k*nbit+1)=>SWAP) for i=1:nbit]) for k=1:nstate-1]),  # get matrix first, very inefficient
        put(N, 1=>H)
        )
end

Yao.mat(ρ::DensityMatrix{1}) = dropdims(state(ρ), dims=3)
