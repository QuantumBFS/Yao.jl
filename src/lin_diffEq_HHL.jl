export array_qudiff, prepare_init_state, LDEMSAlgHHL, bval, aval
export QuEuler, QuLeapfrog, QuAB2, QuAB3, QuAB4
export QuLDEMSProblem

using DiffEqBase
"""
    Based on : arxiv.org/abs/1010.2745v2

    * array_qudiff(N_t,N,h,A) - generates matrix for k-step solver
    * prepare_init_state(b,x,h,N_t) - generates inital states
    * solve_qudiff - solver

    x' = Ax + b

    * A - input matrix.
    * b - input vector.
    * x - inital vector
    * N - dimension of b (as a power of 2).
    * h - step size.
    * tspan - time span.
"""

"""
    LDEMSAlgHHL
    * step - step for multistep method
    * α - coefficients for xₙ
    * β - coefficent for xₙ'
"""
abstract type QuODEAlgorithm <: DiffEqBase.AbstractODEAlgorithm end
#abstract type QuODEProblem{uType,tType,isinplace} <: DiffEqBase.AbstractODEProblem{uType,tType,isinplace} end
abstract type LDEMSAlgHHL <: QuODEAlgorithm end

struct QuLDEMSProblem{F,C,U,T} #<: QuODEProblem{uType,tType,isinplace}
    A::F
    b::C
    u0::U
    tspan::NTuple{2,T}

    #function QuLDEMSProblem(A,b,u0,tspan)
    #  new{typeof(u0),typeof(tspan),false,typeof(A),typeof(b)}(A,b,u0,tspan)
    #end
end

"""
    Explicit Linear Multistep Methods
"""
struct QuEuler{T}<:LDEMSAlgHHL
    step::Int
    α::Vector{T}
    β::Vector{T}

    QuEuler(::Type{T} = Float64) where {T} = new{T}(1,[1.0,],[1.0,])
end

struct QuLeapfrog{T}<:LDEMSAlgHHL
    step::Int
    α::Vector{T}
    β::Vector{T}

    QuLeapfrog(::Type{T} = Float64) where {T} = new{T}(2,[0, 1.0],[2.0, 0])
end
struct QuAB2{T}<:LDEMSAlgHHL
    step::Int
    α::Vector{T}
    β::Vector{T}

    QuAB2(::Type{T} = Float64) where {T} = new{T}(2,[1.0, 0], [1.5, -0.5])
end
struct QuAB3{T}<:LDEMSAlgHHL
    step::Int
    α::Vector{T}
    β::Vector{T}
    QuAB3(::Type{T} = Float64) where {T} = new{T}(3,[1.0, 0, 0], [23/12, -16/12, 5/12])
end
struct QuAB4{T}<:LDEMSAlgHHL
    step::Int
    α::Vector{T}
    β::Vector{T}

    QuAB4(::Type{T} = Float64) where {T} = new{T}(4,[1.0, 0, 0, 0], [55/24, -59/24, 37/24, -9/24])
end

function bval(alg::LDEMSAlgHHL,t,h,g::Function)
    b = zero(g(1))
    for i in 1:(alg.step)
        b += alg.β[i]*g(t-(i-1)*h)
    end
    return b
end

function aval(alg::LDEMSAlgHHL,t,h,g::Function)
    sz, = size(g(1))
    A = Array{ComplexF64}(undef,sz,(alg.step + 1)*sz)
    i_mat = Matrix{Float64}(I, size(g(1)))
    A[1:sz,sz*(alg.step) + 1:sz*(alg.step + 1)] = i_mat
    for i in 1:alg.step
        A[1:sz,sz*(i - 1) + 1: sz*i] = -1*(alg.α[alg.step - i + 1]*i_mat + h*alg.β[alg.step - i + 1]*g(t - (alg.step - i)*h))
    end
    return A
end

function prepare_init_state(tspan::NTuple{2, Float64},x::Vector,h::Float64,g::Function,alg::LDEMSAlgHHL)
    N_t = round(Int, (tspan[2] - tspan[1])/h + 1) #number of time steps
    N = nextpow(2,2*N_t + 1) # To ensure we have a power of 2 dimension for matrix
    sz, = size(g(1))
    init_state = zeros(ComplexF64,2*(N)*sz)
    #inital value
    init_state[1:sz] = x
    for i in 2:N_t
        b = bval(alg,h*(i - 1) + tspan[1],h,g)
        init_state[Int(sz*(i - 1) + 1):Int(sz*(i))] = h*b
    end
    return init_state
end

function array_qudiff(tspan::NTuple{2, Float64},h::Float64,g::Function,alg::LDEMSAlgHHL)
    sz, = size(g(1))
    i_mat = Matrix{Float64}(I, size(g(1)))
    N_t = round(Int, (tspan[2] - tspan[1])/h + 1) #number of time steps
    N = nextpow(2,2*N_t + 1) # To ensure we have a power of 2 dimension for matrix
    A_ = zeros(ComplexF64, N*sz, N*sz)
    # Generates First two rows
    @inbounds A_[1:sz, 1:sz] = i_mat
    @inbounds A_[sz + 1:2*sz, 1:sz] = -1*(i_mat + h*g(tspan[1]))
    @inbounds A_[sz + 1:2*sz,sz+1:sz*2] = i_mat
    #Generates additional rows based on k - step
    for i in 3:alg.step
        @inbounds A_[sz*(i - 1) + 1:sz*i, sz*(i - 3) + 1:sz*i] = aval(QuAB2(),(i-2)*h + tspan[1],h,g)
    end
    for i in alg.step + 1:N_t
        @inbounds A_[sz*(i - 1) + 1:sz*(i), sz*(i - alg.step - 1) + 1:sz*i] = aval(alg,(i - 2)*h + tspan[1],h,g)
    end
    #Generates half mirroring matrix
    for i in N_t + 1:N
        @inbounds A_[sz*(i - 1) + 1:sz*(i), sz*(i - 2) + 1:sz*(i - 1)] = -1*i_mat
        @inbounds A_[sz*(i - 1) + 1:sz*(i), sz*(i - 1) + 1:sz*i] = i_mat
    end
    A_ = [zero(A_) A_;A_' zero(A_)]
    return A_
end

function DiffEqBase.solve(prob::QuLDEMSProblem{F,C,U,T}, alg::LDEMSAlgHHL, dt = (prob.tspan[2]-prob.tspan[1])/100, n_reg::Int = 12) where {F,C,U,T}
    A = prob.A
    b = prob.b
    tspan = prob.tspan
    x = prob.u0

    mat = array_qudiff(tspan, dt, A, alg)
    state = prepare_init_state(tspan, x, dt, b, alg)
    λ = maximum(eigvals(mat))
    C_value = minimum(eigvals(mat) .|> abs)*0.01;
    mat = 1/(λ*2)*mat
    state = state*1/(2*λ) |> normalize!
    res = hhlsolve(mat,state, n_reg, C_value)
    res = res/λ
    return res
end;
