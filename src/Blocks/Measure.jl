export measure, measure!, measure_remove

#########################################
# A naive direct sample on single thread
#########################################

function direct_sample_step(plan::AbstractVector{T}) where {T <: Real}
    dice = rand()
    for (i, each) in enumerate(plan)
        if dice < each
            return i - 1
        end
    end
    # this has the same binary form
    # with the last index, generally,
    # we won't use this return value
    return -1
end

function _generate_sample_plan_from(proposal::AbstractVector{T}) where T
    plan = similar(proposal)
    curr_p = 0
    @inbounds @simd for i in eachindex(plan)
        curr_p += proposal[i]
        plan[i] = curr_p
    end
    plan
end

function direct_sample(proposal::AbstractVector{T}, ntimes::Int) where {T <: Real}
    # TODO: this can be optimized for 2^N state vector
    sample(x) = direct_sample_step(_generate_sample_plan_from(proposal))
    return map(sample, 1:ntimes)
end

######################
# preprocess register
######################

function _reshape_to_active_remain_batch(reg::AbstractRegister{N, B}, m::Int) where {N, B}
    reshape(state(reg), (1<<m, :, B))
end

function _get_reduced_probability_distribution(reg::Register{N, B}, m::Int) where {N, B}
    @assert m <= nactive(reg) "number of active qubits is less than measure qubits"

    s = _reshape_to_active_remain_batch(reg, m)
    reduced_s = reshape(sum(s, 2), (1<<m, B))
    p = abs2.(batch_normalize!(reduced_s))
    [view(p, :, i) for i=1:B]
end

####################
# Measure Functions
####################

function measure(reg::Register, m::Int, ntimes::Int=1)
    # NOTE: do we need to copy register here to preserve its
    # address? address is changed here, but state is not
    p = _get_reduced_probability_distribution(reg, m)
    # direct sampling
    # TODO: use QuMC functions for sampling in the future
    pmap(x->direct_sample(x, ntimes), p)
end

function measure!(reg::Register{N, B, T}, m::Int) where {N, B, T}
    p = _get_reduced_probability_distribution(reg, m)
    plans = map(_generate_sample_plan_from, p)
    samples = map(direct_sample_step, plans)

    full_state_array = _reshape_to_active_remain_batch(reg, m)
    measured_state = zeros(T, 1<<N, B)
    for (i, sample) in enumerate(samples)
        start_index = (1<<(N - m)) * sample + 1
        end_inedx = (1<<(N - m)) * (sample + 1)
        v = view(measured_state, start_index:end_inedx, i)
        v .= full_state_array[sample+1, :, i]
    end
    reg.state = batch_normalize!(measured_state)
    reg, samples
end

function measure_remove(reg::Register{N, B, T}, m::Int) where {N, B, T}
    p = _get_reduced_probability_distribution(reg, m)
    plans = map(_generate_sample_plan_from, p)
    samples = map(direct_sample_step, plans)

    full_state_array = _reshape_to_active_remain_batch(reg, m)
    reduced_state = zeros(T, 1<<(N - m), B)
    for (i, sample) in enumerate(samples)
        reduced_state[:, i] = full_state_array[sample+1, :, i]
    end
    register(reduced_state, B), samples
end

#####################
# Measurement Blocks
#####################

# TODO: add WorkerPool to this block to specify workers for parallelled sampling
mutable struct Measure{M} <: AbstractMeasure{M}
    result::Vector{Int}

    Measure{M}() where M = new{M}()
end

# NOTE: this is just a workaround (cannot dispatch calls in v0.6)
(block::Measure)(reg::Register) = apply!(reg, block)

function apply!(reg::Register, block::Measure{M}) where M
    _, samples = measure!(reg, M)
    block.result = samples
    reg
end

measure(m::Int) = Measure{m}()

mutable struct MeasureAndRemove{M} <: AbstractMeasure{M}
    result::Vector{Int}

    MeasureAndRemove{M}() where M = new{M}()
end

function apply!(reg::Register, block::MeasureAndRemove{M}) where M
    new_reg, samples = measure_remove(reg, M)
    block.result = samples
    new_reg
end

measure_remove(m::Int) = MeasureAndRemove{m}()
