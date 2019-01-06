export heisenberg, iter_groundstate!, itime_groundstate!, vqe_solve!

"""
    heisenberg(nbit::Int; periodic::Bool=true)

heisenberg hamiltonian, for its ground state, refer `PRB 48, 6141`.
"""
function heisenberg(nbit::Int; periodic::Bool=true)
    sx = i->put(nbit, i=>X)
    sy = i->put(nbit, i=>Y)
    sz = i->put(nbit, i=>Z)
    mapreduce(i->(j=i%nbit+1; sx(i)*sx(j)+sy(i)*sy(j)+sz(i)*sz(j)), +, 1:(periodic ? nbit : nbit-1))
end

"""
    iter_groundstate!({reg::AbstractRegister}, h::MatrixBlock; niter::Int=100) -> AbstractRegister

project wave function to ground state by iteratively apply -h.
"""
iter_groundstate!(h::MatrixBlock; niter::Int=100) = reg -> iter_groundstate!(reg, h, niter=niter)
function iter_groundstate!(reg::AbstractRegister, h::MatrixBlock; niter::Int=100)
    for i = 1:niter
        reg |> h
        i%5 == 0 && reg |> normalize!
    end
    reg |> normalize!
end

"""
    itime_groundstate!({reg::AbstractRegister}, h::MatrixBlock; τ::Int=20, tol=1e-4) -> AbstractRegister

Imaginary time evolution method to get ground state, i.e. by projecting wave function to ground state by exp(-hτ). `tol` is for `expmv`.
"""
itime_groundstate!(h::MatrixBlock; τ::Real=20, tol=1e-4) = reg -> itime_groundstate!(reg, h; τ=τ, tol=tol)
function itime_groundstate!(reg::AbstractRegister, h::MatrixBlock; τ::Int=20, tol=1e-4)
    span = 1
    te = timeevolve(h, -im*span)
    for i = 1:τ÷span
        reg |> te |> normalize!
    end
    if τ%span != 0
        reg |> timeevolve(h, τ%span) |> normalize!
    end
    reg
end

# a patch for Yao.expect, to make it faster
function Yao.expect(op::AddBlock, reg::AbstractRegister{1})
    sum(opi->expect(opi, reg), op)
end

"""
    vqe_solve!(circuit::MatrixBlock{N}, hamiltonian::AbstractBlock; niter::Int=100) -> circuit

variational quantum eigensolver, faithful simulation with optimizer Adam(lr=0.01).
"""
function vqe_solve!(circuit::MatrixBlock{N}, hamiltonian::AbstractBlock; niter::Int=100) where N
    optimizer = Adam(lr=0.01)
    dbs = collect(circuit, AbstractDiff)
    params = parameters(circuit)
    for i = 1:niter
        grad = opdiff.(()->zero_state(N) |> circuit, dbs, Ref(hamiltonian))
        dispatch!(circuit, update!(params, grad, optimizer))
        println("Step $i, Energy = $(expect(hamiltonian, zero_state(N) |> circuit))")
    end
    circuit
end
