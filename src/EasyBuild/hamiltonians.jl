export heisenberg, transverse_ising

"""
    heisenberg(nbit::Int; periodic::Bool=true)

1D heisenberg hamiltonian, for its ground state, refer `PRB 48, 6141`.
"""
function heisenberg(nbit::Int; periodic::Bool=true)
    map(1:(periodic ? nbit : nbit-1)) do i
        j=i%nbit+1
        repeat(nbit,X,(i,j)) + repeat(nbit, Y, (i,j)) + repeat(nbit, Z, (i,j))
    end |> sum
end

"""
    transverse_ising(nbit::Int; periodic::Bool=true)

1D transverse ising hamiltonian.
"""
function transverse_ising(nbit::Int; periodic::Bool=true)
    ising_term = map(1:(periodic ? nbit : nbit-1)) do i
        repeat(nbit,Z,(i,i%nbit+1))
    end |> sum
    ising_term + sum(map(i->put(nbit,i=>X), 1:nbit))
end
