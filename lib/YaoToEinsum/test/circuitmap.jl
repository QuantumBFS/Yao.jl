module CircuitMapTest
using YaoToEinsum
using Test, OMEinsum
using YaoBlocks, YaoBlocks.YaoArrayRegister
using SymEngine

const CPhaseGate{T} = ControlBlock{<:ShiftGate{T},<:Any}

@const_gate ISWAP = PermMatrix([1,3,2,4], [1,1.0im,1.0im,1])
@const_gate SqrtX = [0.5+0.5im 0.5-0.5im; 0.5-0.5im 0.5+0.5im]
@const_gate SqrtY = [0.5+0.5im -0.5-0.5im; 0.5+0.5im 0.5+0.5im]
# √W is a non-Clifford gate
@const_gate SqrtW = mat(rot((X+Y)/sqrt(2), π/2))

"""
    singlet_block(θ::Real, ϕ::Real)

The circuit block for initialzing a singlet state.
"""
singlet_block() = chain(put(2, 1=>chain(X, H)), control(2, -1, 2=>X))


mutable struct FSimGate{T<:Number} <: PrimitiveBlock{2}
    theta::T
    phi::T
end
YaoBlocks.nqudits(fs::FSimGate) = 2
YaoBlocks.print_block(io::IO, block::FSimGate) = print(io, "FSim(θ=$(block.theta), ϕ=$(block.phi))")

function Base.:(==)(fs1::FSimGate, fs2::FSimGate)
    return fs1.theta == fs2.theta && fs1.phi == fs2.phi
end

function YaoBlocks.mat(::Type{T}, fs::FSimGate) where T
    θ, ϕ = fs.theta, fs.phi
    T[1 0          0          0;
     0 cos(θ)     -im*sin(θ) 0;
     0 -im*sin(θ) cos(θ)     0;
     0 0          0          exp(-im*ϕ)]
end

YaoBlocks.iparams_eltype(::FSimGate{T}) where T = T
YaoBlocks.getiparams(fs::FSimGate{T}) where T = (fs.theta, fs.phi)
function YaoBlocks.setiparams!(fs::FSimGate{T}, θ, ϕ) where T
    fs.theta = θ
    fs.phi = ϕ
    return fs
end

YaoBlocks.@dumpload_fallback FSimGate FSimGate
YaoBlocks.Optimise.to_basictypes(fs::FSimGate) = fsim_block(fs.theta, fs.phi)

"""
    fsim_block(θ::Real, ϕ::Real)

The circuit representation of FSim gate.
"""
function fsim_block(θ::Real, ϕ::Real)
    if θ ≈ π/2
        return cphase(2,2,1,-ϕ)*SWAP*rot(kron(Z,Z), -π/2)*put(2,1=>phase(-π/4))
    else
        return cphase(2,2,1,-ϕ)*rot(SWAP,2*θ)*rot(kron(Z,Z), -θ)*put(2,1=>phase(θ/2))
    end
end

cphase(nbits::Int, i::Int, j::Int, θ::T) where T = control(nbits, i, j=>shift(θ))
qft_circuit(::Type{T}, n::Int) where T = chain(n, hcphases(T, n, i) for i = 1:n)
hcphases(::Type{T}, n, i) where T = chain(n, i==j ? put(i=>H) : cphase(n, j, i, 2T(π)/T(2^(j-i+1))) for j in i:n);
qft_circuit(n::Int) = qft_circuit(Float64, n)

entangler_google53(::Type{T}, nbits::Int, i::Int, j::Int) where T = put(nbits, (i,j)=>FSimGate(T(π)/2, T(π)/6))

struct Lattice53
    labels::Matrix{Int}
end

function Lattice53(;nbits::Int=53)
    config = ones(Bool, 5, 12)
    config[end,2:2:end] .= false
    config[1, 7] = false
    labels = zeros(Int, 5, 12)
    k = 0
    for (i,c) in enumerate(config)
        if c
            k += 1
            labels[i] = k
            k>=nbits && break
        end
    end
    return Lattice53(labels)
end

nbits(lattice::Lattice53) = maximum(lattice.labels)

function Base.getindex(lattice::Lattice53, i, j)
    1<=i<=size(lattice.labels, 1) && 1<=j<=size(lattice.labels, 2) ? lattice.labels[i,j] : 0
end
upperleft(lattice::Lattice53,i,j) = lattice[i-j%2,j-1]
lowerleft(lattice::Lattice53,i,j) = lattice[i+(j-1)%2,j-1]
upperright(lattice::Lattice53,i,j) = lattice[i-j%2,j+1]
lowerright(lattice::Lattice53,i,j) = lattice[i+(j-1)%2,j+1]

function pattern53(lattice::Lattice53, chr::Char)
    res = Tuple{Int,Int}[]
    # i0, di, j0, dj and direction
    di = 1 + (chr>'D')
    dj = 2 - (chr>'D')
    j0 = 1 + min(dj-1, mod(chr-'A',2))
    direction = 'C'<=chr<='F' ? lowerright : upperright
    for j=j0:dj:12
        i0 = chr>'D' ? mod((chr-'D') + (j-(chr>='G'))÷2, 2) : 1
        for i = i0:di:5
            src = lattice[i, j]
            dest = direction(lattice, i, j)
            src!=0 && dest !=0 && push!(res, (src, dest))
        end
    end
    return res
end

function print_lattice53(lattice, pattern)
    for i_=1:10
        i = (i_+1)÷2
        for j=1:12
            if i_%2 == j%2 && lattice[i,j]!=0
                print(" ∘  ")
            else
                print("    ")
            end
        end
        println()
        for j=1:12
            if i_%2 == j%2 && lattice[i,j]!=0
                hasll = (lowerleft(lattice, i, j), lattice[i,j]) in pattern
                haslr = (lattice[i,j], lowerright(lattice, i, j)) in pattern
                print(hasll ? "/ " : "  ")
                print(haslr ? " \\" : "  ")
            else
                print("    ")
            end
        end
        println()
    end
end

"""
    rand_google53([T=Float64], depth::Int; nbits=53) -> AbstactBlock

Google supremacy circuit with 53 qubits, also know as the Sycamore quantum supremacy circuits. `T` is the parameter type.

References
-------------------------
* Arute, Frank, et al. "Quantum supremacy using a programmable superconducting processor." Nature 574.7779 (2019): 505-510.
"""
rand_google53(depth::Int; nbits::Int=53) = rand_google53(Float64, depth; nbits)
function rand_google53(::Type{T}, depth::Int; nbits::Int=53) where T
    c = chain(nbits)
    lattice = Lattice53(nbits=nbits)
    k = 0
    for pattern in Iterators.cycle(['A', 'B', 'C', 'D', 'C', 'D', 'A', 'B'])
        push!(c, rand_google53_layer(T, lattice, pattern))
        k += 1
        k>=depth && break
    end
    return c
end

function rand_google53_layer(::Type{T}, lattice, pattern) where T
    nbit = nbits(lattice)
    chain(nbit, chain(nbit, [put(nbit, i=>rand([SqrtW, SqrtX, SqrtY])) for i=1:nbit]),
        chain(nbit, [entangler_google53(T, nbit,i,j) for (i,j) in pattern53(lattice, pattern)])
        )
end

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

@testset "YaoToEinsum.jl" begin
    n = 5
    a = rand_unitary(4)[:, 1:2]
    a1 = rand_unitary(4)[:, 2]
    mb = matblock(OuterProduct(conj.(a), a))
    mb1 = matblock(OuterProduct(conj.(a1), a1))
    for c in [put(n, 2=>Y), put(n, 2=>ConstGate.P0), put(n, (3,2)=>mb1), put(n, (2, 1)=>mb), put(n, 2=>ConstGate.P1), put(n, (5,3)=>SWAP), put(n, (4,2)=>ConstGate.CNOT), put(n, (2,3,1)=>kron(ConstGate.CNOT, X)),
            put(n, 2=>Z), control(n, -3, 2=>X), control(n, 3, 2=>X), control(n, (2, -1), 3=>Y), control(n, (4,1,-2), 5=>Z)]
        @show c
        C = chain([put(n, i=>Rx(rand()*2π)) for i=1:n]..., c)
        code, xs = yao2einsum(C; optimizer=nothing)
        optcode = optimize_code(code, uniformsize(code, 2), GreedyMethod())
        @test reshape(optcode(xs...; size_info=uniformsize(code, 2)), 1<<n, 1<<n) ≈ mat(C)
    end
end

@testset "Yao Extensions" begin
    n = 5
    for c in [qft_circuit(n), variational_circuit(n, 2), rand_google53(5; nbits=n)]
        optcode, xs = yao2einsum(c)
        @test reshape(optcode(xs...; size_info=uniformsize(optcode, 2)), 1<<n, 1<<n) ≈ mat(c)
    end
end

@testset "boundary conditions" begin
    for i=1:10
        n = 5
        c = qft_circuit(n)
        initial_state = Dict([i=>rand_state(1) for i=1:n])
        reg = join([initial_state[i] for i=n:-1:1]...)
        reg |> c
        inner = (2,3)
        focus!(reg, inner)
        for final_state in [Dict([i=>rand_state(1) for i in inner]), Dict([i=>1 for i in inner])]
            freg = join(YaoToEinsum.render_single_qudit_state(ComplexF64, 2, final_state[3]), YaoToEinsum.render_single_qudit_state(ComplexF64, 2, final_state[2]))
            net = yao2einsum(c; initial_state=initial_state, final_state=final_state, optimizer=TreeSA(nslices=3, niters=10, ntrials=1))
            println(net)
            @test vec(contract(net)) ≈ vec(statevec(freg)' * state(reg))
        end
    end
end

@testset "symbolic" begin
    n = 5
    c = qft_circuit(n)
    initial_state = Dict([i=>zero_state(Basic, 1) for i=1:n])
    code, xs = yao2einsum(c; initial_state=initial_state)
    @test eltype(xs) == AbstractArray{Basic}
end

@testset "fix to basic type" begin
    c = chain(kron(X,X))
    @test (yao2einsum(c) |> first) isa OMEinsum.SlicedEinsum
end

@testset "multiple qubit states" begin
    n = 4
    reg1 = rand_state(2)
    reg2 = rand_state(2)
    reg3 = rand_state(1)
    reg4 = rand_state(3)
    c = chain(4)
    code, xs = yao2einsum(c; initial_state=Dict([1, 2]=>reg1, [3, 4]=>reg2), final_state=Dict([1]=>reg3, [2,3,4]=>reg4))
    @test code(xs...; size_info=uniformsize(code, 2))[] ≈ join(reg4, reg3)' * join(reg2, reg1)
end

@testset "multi-level" begin
    N2 = OnLevels{3}(ConstGate.P1, (2, 3))
    X01 = OnLevels{3}(ConstGate.P1, (1, 2))
    X12 = OnLevels{3}(ConstGate.P1, (2, 3))
    function qaoa_circuit(nbits::Int, depth::Int)
        n2 = chain([kron(nbits, i=>N2, i+1=>N2) for i=1:nbits-1])
        x01 = chain([put(nbits, i=>X01) for i=1:nbits])
        x12 = chain([put(nbits, i=>X12) for i=1:nbits])
        return chain(repeat([n2, x01, x12], depth))
    end

    c = qaoa_circuit(5, 2)
    op = repeat(5, X01)
    extc = chain(c, op, c') 

    res = yao2einsum(extc, initial_state=Dict(zip(1:5, zeros(Int, 5))), final_state=Dict(zip(1:5, zeros(Int, 5))))
    @test res isa TensorNetwork
    expected = expect(op, zero_state(ComplexF64, 5; nlevel=3) |> c)
    @test res.code(res.tensors...; size_info=uniformsize(res.code, 3))[] ≈ expected
end

@testset "matblock" begin
    c = matblock(randn(ComplexF64, 4, 4))
    @test yao2einsum(c) isa TensorNetwork
    @test contract(yao2einsum(c)) ≈ reshape(mat(c), 2, 2, 2, 2)
end

end
