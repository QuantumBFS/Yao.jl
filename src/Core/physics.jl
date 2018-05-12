using StatsBase: sample, fit, Histogram, Weights

sample_from_prob(data::Vector{T}, p::Vector{Float64}, num_sample::Int) where T<:Number = sample(data, Weights(p), num_sample)
# here sample(weight, n) is straight
sample_from_prob(p::Vector{Float64}, num_sample::Int) = sample(collect(1:length(p)), Weights(p), num_sample)

"""
emperical probability from data.
"""
function prob_from_sample(sample::Vector{T}, hndim::Int) where T<:Number
    w = fit(Histogram, sample, 0:hndim, closed=:left).weights
    w/sum(w)
end

# we already have entropy, crossentropy and kldivergence from StatsBase
