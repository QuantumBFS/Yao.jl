export heisenberg, transverse_ising, rydberg_chain

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

# a 3 level hamiltonian
function rydberg_chain(nbits::Int; Ω::Number=0.0, Δ::Real=0.0, V::Real=0.0, r::Real=0.0)
    Pr = matblock(sparse([3], [3], [1.0+0im], 3, 3); nlevel=3)
    Z1r = matblock(sparse([2, 3], [2, 3], [1.0+0im, -1.0], 3, 3); nlevel=3)
    X1r = matblock(sparse([2, 3], [3, 2], [1.0+0im, 1.0], 3, 3); nlevel=3)
    X01 = matblock(sparse([1, 2], [2, 1], [1.0+0im, 1.0], 3, 3); nlevel=3)
    Y1r = matblock(sparse([3, 2], [2, 3], [1.0im, -1.0im], 3, 3); nlevel=3)
    # single site term in {|1>, |r>}.
    h = Add(nbits; nlevel=3)
    !iszero(Δ) && push!(h, (-Δ) * sum([put(nbits, i=>Pr) for i=1:nbits]))
    #!iszero(Δ) && push!(h, (-Δ/2) * sum([put(nbits, i=>Z1r) for i=1:nbits]))
    !iszero(real(Ω)) && push!(h, real(Ω)/2 * sum([put(nbits, i=>X1r) for i=1:nbits]))
    !iszero(imag(Ω)) && push!(h, imag(Ω)/2 * sum([put(nbits, i=>Y1r) for i=1:nbits]))
    # interaction
    !iszero(V) && nbits > 1 && push!(h, V * sum([put(nbits, (i,i+1)=>kron(Pr, Pr)) for i=1:nbits-1]))
    # Raman term
    !iszero(r) && push!(h, r * sum([put(nbits, i=>X01) for i=1:nbits]))
    return h
end