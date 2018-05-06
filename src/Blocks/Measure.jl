export measure, measure!, measure_remove!

# A naive direct sample on single thread

function direct_sample_step(list::Vector{T}) where {T <: Real}
    dice = rand()
    for (i, each) in enumerate(list)
        if dice < each
            return i - 1
        end
    end
    return -1
end

function direct_sample(proposal::Vector{T}, ntimes::Int) where {T <: Real}
    # TODO: this can be optimized for 2^N state vector
    sample(x) = direct_sample_step([sum(view(proposal, 1:k)) for k = 1:length(proposal)])

    # TODO: parallel this
    return map(sample, 1:ntimes)
end

function get_reduced_probability_distribution(reg::Register{N, B}, m::Int) where {N, B}
    @assert m < nactive(reg) "number of active qubits is less than measure qubits"

    s = reshape(state(reg), (m, :, B))
    reduced_s = reshape(sum(s, 2), (m, B))
    p = abs2.(reduced_s)
    [normalize(view(p, :, i)) for i=1:B]
end

function measure(reg::Register, m::Int, ntimes::Int=1)
    # NOTE: do we need to copy register here to preserve its
    # address? address is changed here, but state is not
    p = get_reduced_probability_distribution(reg, m)
    # direct sampling
    # TODO: use QuMC functions for sampling in the future
    # TODO: parallel this
    map(x->direct_sample(x, ntimes), p)
end

function measure!(reg::Register, address::NTuple{M, Int}) where M
    p = get_reduced_probability_distribution(reg, address)
    direct_sample_step([sum(view(p, 1:k)) for k = 1:length(p)])
    reg.state
end

function measure_remove!(reg::Register, addr::NTuple{M, Int}) where M
    p = get_reduced_probability_distribution(reg, addr)
    sample = direct_sample_step([sum(view(p, 1:k)) for k = 1:length(p)])
    Register{N - M, nbatch, T}(state, collect(1:N))
    Register(reg.state[p+1, :], address(reg)[M+1:end])
end

mutable struct Measure{M} <: AbstractMeasure{M}
    result::Int
end

mutable struct MeasureAndRemove{M} <: AbstractMeasure{M}
    result::Int
end
