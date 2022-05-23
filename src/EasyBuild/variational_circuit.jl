using YaoArrayRegister.StatsBase: sample

export variational_circuit

################## Entangler ###################
"""
    pair_ring(n::Int) -> Vector

Pair ring entanglement layout.
"""
pair_ring(n::Int) = [i=>mod(i, n)+1 for i=1:n]

"""
    pair_square(m::Int, n::Int) -> Vector

Pair square entanglement layout.
"""
function pair_square(m::Int, n::Int; periodic=false)
    res = Vector{Pair{Int, Int}}(undef, (m-!periodic)*n+m*(n-!periodic))
    li = LinearIndices((m, n))
    k = 1
    for i = 1:2:m, j=1:n
        if periodic || i<m
            res[k] = li[i, j] => li[i%m+1, j]
            k+=1
        end
    end
    for i = 2:2:m, j=1:n
        if periodic || i<m
            res[k] = li[i, j] => li[i%m+1, j]
            k+=1
        end
    end
    for i = 1:m, j=1:2:n
        if periodic || j<n
            res[k] = li[i, j] => li[i, j%n+1]
            k+=1
        end
    end
    for i = 1:m, j=2:2:n
        if periodic || j<n
            res[k] = li[i, j] => li[i, j%n+1]
            k+=1
        end
    end
    res
end

###################### rotor and rotorset #####################
"""
    merged_rotor(noleading::Bool=false, notrailing::Bool=false) -> ChainBlock{1, ComplexF64}

Single qubit arbitrary rotation unit, set parameters notrailing, noleading true to remove trailing and leading Z gates.

!!! note

    Here, `merged` means `Rz(η)⋅Rx(θ)⋅Rz(ξ)` are multiplied first, this kind of operation if now allowed in differentiable
    circuit with back-propagation (`:BP`) mode (just because we are lazy to implement it!).
    But is a welcoming component in quantum differentiation.
"""
merged_rotor(::Type{T}, noleading::Bool=false, notrailing::Bool=false) where T = noleading ? (notrailing ? Rx(zero(T)) : chain(Rx(zero(T)), Rz(zero(T)))) : (notrailing ? chain(Rz(zero(T)), Rx(zero(T))) : chain(Rz(zero(T)), Rx(zero(T)), Rz(zero(T))))

"""
    rotor(nbit::Int, ibit::Int, noleading::Bool=false, notrailing::Bool=false) -> ChainBlock{nbit, ComplexF64}

Arbitrary rotation unit (put in `nbit` space), set parameters notrailing, noleading true to remove trailing and leading Z gates.
"""
function rotor(::Type{T}, nbit::Int, ibit::Int, noleading::Bool=false, notrailing::Bool=false) where T
    rt = chain(nbit, [put(nbit, ibit=>Rz(zero(T))), put(nbit, ibit=>Rx(zero(T))), put(nbit, ibit=>Rz(zero(T)))])
    noleading && popfirst!(rt)
    notrailing && pop!(rt)
    rt
end

rotorset(::Type{T}, ::Val{:Merged}, nbit::Int, noleading::Bool=false, notrailing::Bool=false) where T = chain(nbit, [put(nbit, j=>merged_rotor(T, noleading, notrailing)) for j=1:nbit])
rotorset(::Type{T}, ::Val{:Split}, nbit::Int, noleading::Bool=false, notrailing::Bool=false) where T = chain(nbit, [rotor(T, nbit, j, noleading, notrailing) for j=1:nbit])
rotorset(::Type{T}, mode::Symbol, nbit::Int, noleading::Bool=false, notrailing::Bool=false) where T = rotorset(T, Val(mode), nbit, noleading, notrailing)

"""
    variational_circuit([T=Float64], nbit[, nlayer][, pairs]; mode=:Split, do_cache=false, entangler=cnot)

A kind of widely used differentiable quantum circuit, angles in the circuit is randomely initialized.

### Arguments

* `T` is the parameter type.
* `pairs` is list of `Pair`s for entanglers in a layer, default to `pair_ring` structure,
* `mode` can be :Split or :Merged,
* `do_cache` decides whether cache the entangler matrix or not,
* `entangler` is a constructor returns a two qubit gate, `f(n,i,j) -> gate`.
    The default value is `cnot(n,i,j)`.

### References

1. Kandala, A., Mezzacapo, A., Temme, K., Takita, M., Chow, J. M., & Gambetta, J. M. (2017). Hardware-efficient Quantum Optimizer for Small Molecules and Quantum Magnets. Nature Publishing Group, 549(7671), 242–246. https://doi.org/10.1038/nature23879.
"""
function variational_circuit(::Type{T}, nbit, nlayer, pairs; mode=:Split, do_cache=false, entangler=cnot) where T
    circuit = chain(nbit)

    ent = chain(nbit, entangler(nbit, i, j) for (i, j) in pairs)
    if do_cache
        ent = ent |> cache
    end
    has_param = nparameters(ent) != 0
    for i = 1:(nlayer + 1)
        i!=1 && push!(circuit, has_param ? deepcopy(ent) : ent)
        push!(circuit, rotorset(T, mode, nbit, i==1, i==nlayer+1))
    end
    circuit
end

variational_circuit(::Type{T}, n::Int; kwargs...) where T = variational_circuit(T, n, 3, pair_ring(n); kwargs...)

variational_circuit(::Type{T}, nbit::Int, nlayer::Int; kwargs...) where T = variational_circuit(T, nbit, nlayer, pair_ring(nbit); kwargs...)
variational_circuit(nbit::Int; kwargs...) = variational_circuit(Float64, nbit; kwargs...)
variational_circuit(nbit::Int, nlayer::Int; kwargs...) = variational_circuit(Float64, nbit, nlayer; kwargs...)
