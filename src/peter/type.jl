mutable struct Observable{T<:Union{AbstractArray, Number}} # TODO: What are allowed types of observables? As a group there should be the concept of a mean.
    name::String

    entry_size::Vector{Int}
    last_dim::Int
    colons::Vector{Colon}

    n_measurements::Int
    keep_timeseries::Int
    timeseries::Array{T}
    measurement_buffer::Array{T}
    bins::Array{T}
    bin_variance_series::Array{T}
    curr_bin::Int
    autocorrelation_buffer::Array{T}

end

# TODO: constructors
# Observable(name::String, entry_size::Array{Int, 1}=[1]) = new(name, 1, false, size(entry_size, 1) + 1, entry_size, prod(entry_size), typemin(T) * ones(entry_size..., 0), typemin(T) * ones(entry_size..., 1), typemin(T) * ones(entry_size..., 2^8), typemin(T) * ones(T, entry_size..., 16), 1, typemin(T) * ones(T, entry_size..., 2^10), [Colon() for _ in entry_size])