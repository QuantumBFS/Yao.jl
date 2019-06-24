export num_gradient, diff_blocks, loss, circuit, QCOptProblem, QCOptGo!

"""
    QCOptProblem

General quantum circuit optimization problem interface
"""
abstract type QCOptProblem end

"""
    circuit(qop::QCOptProblem) -> AbstractBlock

circuit to optimize
"""
function circuit end

"""
    loss(qop::QCOptProblem) -> Real

Return the loss.
"""
function loss end

#####################################################

"""
    gradient(qop::QCOptProblem) -> Vector

the gradients with respect to `diff_blocks`.
"""
function gradient end

"""
    diff_blocks(qop::QCOptProblem) -> iterable

collection of all differentiable units.
"""
diff_blocks(qop::QCOptProblem) = collect_blocks(Diff, qop |> circuit)

"""
    num_gradient(qop::QCOptProblem) -> Vector

obtain the gradient numerically
"""
num_gradient(qop::QCOptProblem) = numdiff.(()->loss(qop), qop |> diff_blocks)

################# Optimization ###################
"""
    QCOptGo!{QT}

quantum circuit optimization problem optimizer.
"""
abstract type QCOptGo!{QT} end

include("QuGAN.jl")
include("QCBM.jl")
