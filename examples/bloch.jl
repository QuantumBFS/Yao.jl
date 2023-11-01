using YaoPlots, Yao
using LinearAlgebra: axpy!

function commutator(x, y; ishermitian=false)
    res = x * y
    if ishermitian
        return res - res'
    else
        return res - y * x
    end
end
function anticommutator(x, y; ishermitian=false)
    res = x * y
    if ishermitian
        return res + res'
    else
        return res + y * x
    end
end

# single step master equation
function mestep(rho::DensityMatrix{D}, h, Ls, dt) where D
    res = copy(rho.state)
    # The im*[ρ, H] term.
    # NOTE: transposed storage is faster
    reg = arrayreg(copy(rho.state)'; nlevel=size(rho.state, 2))
    apply!(reg, h)
    axpy!(dt * im, reg.state' - reg.state, res)
    for L in Ls
        # the LρL' term
        axpy!(dt, apply(rho, L).state, res)
        # the -(ρL'L + L'Lρ)/2 term
        reg = arrayreg(copy(rho.state)'; nlevel=size(rho.state, 2))
        apply!(reg, L' * L)
        axpy!(-0.5dt, reg.state, res)
        axpy!(-0.5dt, reg.state', res)
    end
    return DensityMatrix(res)
end

function simulate(t; dt=0.02, dissiplation=0.2, filename=nothing)
    reg0 = zero_state(1) |> H
    rho = density_matrix(reg0)
    h = Z    # rotate around Z
    Ls = [sqrt(dissiplation) * ConstGate.Pd]  # dissipation
    states = ["|+⟩"=>rho]
    for t = 0:dt:t
        rho = mestep(rho, h, Ls, dt)
        push!(states, ""=>rho)
    end
    return bloch_sphere(states...; filename)
end

simulate(π/2; filename=joinpath(@__DIR__, "mesolve.png"))