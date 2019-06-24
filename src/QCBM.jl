import Yao: probs
export QCBM, QCBMGo!, psi, mmdgrad

include("Kernels.jl")

##### QCBM methods #####
struct QCBM{BT<:AbstractBlock, KT<:AbstractKernel} <: QCOptProblem
    circuit::BT
    kernel::KT
    ptrain::Vector{Float64}

    dbs
end
function QCBM(circuit::AbstractBlock, kernel::AbstractKernel, ptrain::Vector)
    QCBM(circuit, kernel, ptrain, collect_blocks(Diff, circuit))
end

# INTERFACES
circuit(qcbm::QCBM) = qcbm.circuit
diff_blocks(qcbm::QCBM) = qcbm.dbs
"""
    loss(qcbm::QCBM, [p=qcbm|>probs]) -> Float64

loss function, optional parameter `p` is the probability distribution.
"""
function loss(qcbm::QCBM, p=qcbm|>probs)
    p -= qcbm.ptrain
    kernel_expect(qcbm.kernel, p, p)
end
"""
    gradient(qcbm::QCBM, p0=qcbm |> probs) -> Vector

gradient of MMD two sample test loss, `db` must be contained in qcbm.
optional parameter `p0` is current probability distribution.
"""
gradient(qcbm::QCBM, p0=qcbm |> probs) = mmdgrad.(Ref(qcbm), qcbm.dbs, p0=p0)

"""generated wave function"""
psi(qcbm) = zero_state(qcbm.circuit |> nqubits) |> qcbm.circuit
"""generated probability distribution"""
probs(qcbm::QCBM) = qcbm |> psi |> probs
"""
    mmdgrad(qcbm::QCBM, db::Diff; p0::Vector) -> Float64

gradient of MMD two sample test loss, `db` must be contained in qcbm.
`p0` is current probability distribution.
"""
function mmdgrad(qcbm::QCBM, db::Diff; p0::Vector)
    statdiff(()->probs(qcbm) |> as_weights, db, StatFunctional(kmat(qcbm.kernel)), initial=p0 |> as_weights) -
        2*statdiff(()->probs(qcbm) |> as_weights, db, StatFunctional(kmat(qcbm.kernel)*qcbm.ptrain))
end

"""
quantum circuit born machine trainer.
"""
struct QCBMGo!{QT<:QCBM, OT} <: QCOptGo!{QT}
    qcbm::QT
    optimizer::OT
    niter::Int
end
QCBMGo!(qcbm::QCBM, optimizer) = QCBMGo!(qcbm, optimizer, typemax(Int))
Base.length(qo::QCBMGo!) = qo.niter

function Base.iterate(qo::QCBMGo!, state=(1, parameters(qo.qcbm.circuit)))
    state[1] > qo.niter && return nothing

    # initialize the parameters
    p0 = qo.qcbm |> probs
    grad = gradient(qo.qcbm, p0)
    update!(state[2], grad, qo.optimizer)
    dispatch!(qo.qcbm.circuit, state[2])
    Dict("probs"=>p0, "step"=>state[1], "gradient"=>grad), (state[1]+1, state[2])
end
