type Observable{T} where T
    name::String
    n_measurements::Int
    keep_timeseries::Int
    last_dim::Int
    entry_dims::Array{Int, 1}
    entry_size::Int
    timeseries::Array{T}
    measurement_buffer::Array{T}
    bins::Array{T}
    bin_variance_series::Array{T}
    curr_bin::Int
    autocorrelation_buffer::Array{T}
    colons::Array{Colon}

end

# TODO: constructors
# Observable(name::String, entry_dims::Array{Int, 1}=[1]) = new(name, 1, false, size(entry_dims, 1) + 1, entry_dims, prod(entry_dims), typemin(T) * ones(entry_dims..., 0), typemin(T) * ones(entry_dims..., 1), typemin(T) * ones(entry_dims..., 2^8), typemin(T) * ones(T, entry_dims..., 16), 1, typemin(T) * ones(T, entry_dims..., 2^10), [Colon() for _ in entry_dims])