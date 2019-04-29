using Yao
using BitBasis
using QuAlgorithmZoo
using Test, LinearAlgebra

function crot(n_reg::Int, C_value::Real)
    n_rot = n_reg + 1
    rot   = chain(n_rot)
    θ = zeros(1<<n_reg - 1)
    for i = 1:(1<<n_reg - 1)
        c_bit = Vector(2:n_rot)
        λ = 0.0
        for j = 1:n_reg
            if (readbit(i,j) == 0)
                c_bit[j] = -c_bit[j]
            end
        end
        λ = i/(1<<n_reg)
        # println("\nλ($i) = $λ")
        # println("c_bit($i) = $c_bit\n")
        sin_value = C_value / λ
        if (sin_value) > 1
            return println("C_value = $C_value, λ = $λ, sinθ = $sin_value > 1, please lower C_value.\n")
        end
        θ[(i)] = 2.0*asin(C_value / λ)
        push!(rot, control(c_bit, 1=>Ry(θ[(i)])))
    end
    rot
end

@testset "HHLCRot" begin
    hr = HHLCRot{4}([4,3,2], 1, 0.01)
    reg = rand_state(4)
    @test reg |> copy |> hr |> isnormalized

    hr2 = crot(3, 0.01)
    reg1 = reg |> copy |> hr
    reg2 = reg |> copy |> hr2
    @test fidelity(reg1, reg2)[] ≈ 1
end

"""
    hhl_problem(nbit::Int) -> Tuple

Returns (A, b), where
    * `A` is positive definite, hermitian, with its maximum eigenvalue λ_max < 1.
    * `b` is normalized.
"""
function hhl_problem(nbit::Int)
    siz = 1<<nbit
    base_space = qr(randn(ComplexF64, siz, siz)).Q
    phases = rand(siz)
    signs = Diagonal(phases)
    A = base_space*signs*base_space'

    # reinforce hermitian, see issue: https://github.com/JuliaLang/julia/issues/28885
    A = (A+A')/2
    b = normalize(rand(ComplexF64, siz))
    A, b
end

@testset "HHLtest" begin
    # Set up initial conditions.
    ## A: Matrix in linear equation A|x> = |b>.
    ## signs: Diagonal Matrix of eigen values of A.
    ## base_space: the eigen space of A.
    ## x: |x>.
    using Random
    Random.seed!(2)
    N = 3
    A, b = hhl_problem(N)
    x = A^(-1)*b # base_i = base_space[:,i] ϕ1 = (A*base_i./base_i)[1]

    ## n_b  : number of bits for |b>.
    ## n_reg: number of PE register.
    ## n_all: number of all bits.
    n_reg = 12

    ## C_value: value of constant C in control rotation.
    ## It should be samller than the minimum eigen value of A.
    C_value = minimum(eigvals(A) .|> abs)*0.25
    #C_value = 1.0/(1<<n_reg) * 0.9
    res = hhlsolve(A, b, n_reg, C_value)

    # Test whether HHL circuit returns correct coefficient of |1>|00>|u>.
    @test isapprox.(x, res, atol=0.5) |> all
end
