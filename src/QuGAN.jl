using MacroTools: @forward
import Yao: tracedist

export QuGAN, psi, toy_qugan, QuGANGo!

"""
Quantum GAN.

Reference:
    Benedetti, M., Grant, E., Wossnig, L., & Severini, S. (2018). Adversarial quantum circuit learning for pure state approximation, 1–14.
"""
struct QuGAN{N} <: QCOptProblem
    target::ArrayReg
    generator::MatrixBlock{N}
    discriminator::MatrixBlock
    reg0::ArrayReg
    witness_op::MatrixBlock
    circuit::AbstractBlock
    gdiffs
    ddiffs

    function QuGAN(target::ArrayReg, gen::MatrixBlock, dis::MatrixBlock)
        N = nqubits(target)
        c = Sequence([gen, addbits!(1), dis])
        witness_op = put(N+1, (N+1)=>P0)
        gdiffs = collect_blocks(AbstractDiff, gen)
        ddiffs = collect_blocks(AbstractDiff, dis)
        new{N}(target, gen, dis, zero_state(N), witness_op, c, gdiffs, ddiffs)
    end
end

# INTERFACES
circuit(qg::QuGAN) = qg.circuit
diff_blocks(qg::QuGAN) = [qg.gdiffs...; qg.ddiffs...]
loss(qg::QuGAN) = p0t(qg) - p0g(qg)
function gradient(qg::QuGAN)
    ggrad_g = opdiff.(()->psi_discgen(qg), qg.gdiffs, Ref(qg.witness_op))
    dgrad_g = opdiff.(()->psi_discgen(qg), qg.ddiffs, Ref(qg.witness_op))
    dgrad_t = opdiff.(()->psi_disctarget(qg), qg.ddiffs, Ref(qg.witness_op))
    [-ggrad_g; dgrad_t - dgrad_g]
end

"""probability to get evidense qubit 0 on generation set."""
p0g(qg::QuGAN) = expect(qg.witness_op, psi_discgen(qg)) |> real
"""probability to get evidense qubit 0 on target set."""
p0t(qg::QuGAN) = expect(qg.witness_op, psi_disctarget(qg)) |> real
"""generated wave function"""
psi(qg::QuGAN) = copy(qg.reg0) |> qg.generator
"""input |> generator |> discriminator"""
psi_discgen(qg::QuGAN) = copy(qg.reg0) |> qg.circuit
"""target |> discriminator"""
psi_disctarget(qg::QuGAN) = copy(qg.target) |> qg.circuit[2:end]
"""tracedistance between target and generated wave function"""
tracedist(qg::QuGAN) = tracedist(qg.target, psi(qg))[]

"""
    toy_qugan(target::ArrayReg, depth_gen::Int, depth_disc::Int) -> QuGAN

Construct a toy qugan.
"""
function toy_qugan(target::ArrayReg, depth_gen::Int, depth_disc::Int)
    n = nqubits(target)
    generator = dispatch!(random_diff_circuit(n, depth_gen, pair_ring(n)), :random) |> autodiff(:QC)
    discriminator = dispatch!(random_diff_circuit(n+1, depth_disc, pair_ring(n+1)), :random) |> autodiff(:QC)
    return QuGAN(target, generator, discriminator)
end

# Optimization
"""
    QuGANGo!{QT<:QuGAN, OT} <: QCOptGo!{QT}

Iterative training of quantum generative optimization problem,
QT is the type of quantum optimization problem,
OT is the optimizer/learning_rate parameter type.
"""
struct QuGANGo!{QT<:QuGAN, OT} <: QCOptGo!{QT}
    qop::QT
    goptim::OT
    doptim::OT
    niter::Int
end
QuGANGo!(qg::QuGAN, glr, dlr) = QuGANGo!(qg, glr, dlr, typemax(Int))
Base.length(qgg::QuGANGo!) = qgg.niter

function Base.iterate(qgg::QuGANGo!{<:Any, <:Real}, state=1)
    state > qgg.niter && return nothing

    qg = qgg.qop
    ng = length(qg.gdiffs)
    grad = gradient(qg)
    dispatch!(+, qg.generator, -grad[1:ng]*qgg.goptim)
    dispatch!(-, qg.discriminator, -grad[ng+1:end]*qgg.doptim)
    Dict("step"=>state,"gradient"=>grad), state+1
end

function Base.iterate(qgg::QuGANGo!{<:Any, <:Adam}, state=(1, parameters(qgg.qop.generator), parameters(qgg.qop.discriminator)))
    state[1] > qgg.niter && return nothing

    qg = qgg.qop
    ng = length(qg.gdiffs)
    grad = gradient(qg)
    dispatch!(qg.generator, update!(state[2], grad[1:ng], qgg.goptim))
    dispatch!(qg.discriminator, update!(state[3], -grad[ng+1:end], qgg.doptim))
    Dict("step"=>state[1], "gradient"=>grad), (state[1]+1, state[2], state[3])
end
