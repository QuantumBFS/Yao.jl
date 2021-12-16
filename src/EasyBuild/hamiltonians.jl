export heisenberg, transverse_ising

"""
    heisenberg(nbit::Int; periodic::Bool=true)

1D Heisenberg hamiltonian defined as ``\\sum_{i=1}^{n} X_{i}X_{i+1} + Y_{i}Y_{i+1} + Z_{i}Z_{i+1}``, where ``n`` is specified by `nbit`.
`periodic` means the boundary condition is periodic.

References
----------------------
* de Oliveira, Mário J. "Ground-state properties of the spin-1/2 antiferromagnetic Heisenberg chain obtained by use of a Monte Carlo method." Physical Review B 48.9 (1993): 6141-6143.
"""
function heisenberg(nbit::Int; periodic::Bool=true)
    map(1:(periodic ? nbit : nbit-1)) do i
        j=i%nbit+1
        repeat(nbit,X,(i,j)) + repeat(nbit, Y, (i,j)) + repeat(nbit, Z, (i,j))
    end |> sum
end

"""
    transverse_ising(nbit::Int, h::Number; periodic::Bool=true)

1D transverse Ising hamiltonian defined as ``\\sum_{i=1}^{n} hX_{i} + Z_{i}Z_{i+1}``, where ``n`` is specified by `nbit`.
`periodic` means the boundary condition is periodic.
"""
function transverse_ising(nbit::Int, h::Number; periodic::Bool=true)
    ising_term = map(1:(periodic ? nbit : nbit-1)) do i
        repeat(nbit,Z,(i,i%nbit+1))
    end |> sum
    ising_term + h*sum(map(i->put(nbit,i=>X), 1:nbit))
end
