export iter_groundstate!, itime_groundstate!, vqe_solve!

"""
    iter_groundstate!({reg::AbstractRegister}, h::AbstractBlock; niter::Int=100) -> AbstractRegister

project wave function to ground state by iteratively apply -h.
"""
iter_groundstate!(h::AbstractBlock; niter::Int=100) = reg -> iter_groundstate!(reg, h, niter=niter)
function iter_groundstate!(reg::AbstractRegister, h::AbstractBlock; niter::Int=100)
    for i = 1:niter
        reg |> h
        i%5 == 0 && reg |> normalize!
    end
    reg |> normalize!
end

"""
    itime_groundstate!({reg::AbstractRegister}, h::AbstractBlock; τ::Int=20, tol=1e-4) -> AbstractRegister

Imaginary time evolution method to get ground state, i.e. by projecting wave function to ground state by exp(-hτ). `tol` is for `expmv`.
"""
itime_groundstate!(h::AbstractBlock; τ::Real=20, tol=1e-4) = reg -> itime_groundstate!(reg, h; τ=τ, tol=tol)
function itime_groundstate!(reg::AbstractRegister, h::AbstractBlock; τ::Int=20, tol=1e-4)
    span = 1.0
    te = time_evolve(h, -im*span)
    for i = 1:τ÷span
        reg |> te |> normalize!
    end
    if τ%span != 0
        reg |> time_evolve(h, τ%span) |> normalize!
    end
    reg
end

"""
    vqe_solve!(circuit::AbstractBlock{N}, hamiltonian::AbstractBlock; niter::Int=100) -> circuit

variational quantum eigensolver, faithful simulation with optimizer Adam(lr=0.01).
"""
function vqe_solve!(circuit::AbstractBlock{N}, hamiltonian::AbstractBlock; niter::Int=100) where N
    optimizer = Adam(lr=0.01)
    dbs = collect_blocks(Diff, circuit)
    params = parameters(circuit)
    for i = 1:niter
        grad = opdiff.(()->zero_state(N) |> circuit, dbs, Ref(hamiltonian))
        dispatch!(circuit, update!(params, grad, optimizer))
        println("Step $i, Energy = $(expect(hamiltonian, zero_state(N) |> circuit))")
    end
    circuit
end
