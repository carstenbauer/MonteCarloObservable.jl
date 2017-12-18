using StatsBase

function Base.mean{T}(mco::monte_carlo_observable{T})
    return mean(mco.bins[mco.colons..., 1:(mco.curr_bin - 1)], mco.last_dim)
end

###################################################
# Autocorrelation times
###################################################

function A{T}(t::Array{T}, k, variance, mean)
    last_dim = length(size(t))
    N = size(t)[last_dim]
    colons = [Colons() for _ in 1:last_dim - 1]
    terms = cat(last_dim, [xs[colons..., i] .* xs[colons..., i + k] - m.^2 for i in 1:(N - 1 - k)]...)
    return 1. ./ v * mean(terms, last_dim)
end


function integrated_autocorrelation_time{T}(t::Array{T})
    last_dim = length(size(t))
    N = size(t, last_dim)
    tau = zeros(T, size(t)[1:end - 1]...)

    for k in 1:size(t, last_dim)
        v = var(t, last_dim)
        m = mean(t, last_dim)

        tau += (1 - k / N) * A(t, k, v, m)
        if (abs(A(k)) .< 1e-3) == (k .>= 6 * tau)
            break
        end
    end

    return tau
end


function integrated_autocorrelation_time{T}(mco::monte_carlo_observable{T})
    ac_buffer_size = size(mco.autocorrelation_buffer)[end]

    # Nmax = min(mco.n_measurements, ac_buffer_size)
    split_buffer_entry = mco.n_measurements > ac_buffer_size ? mod1(mco.n_measurements, ac_buffer_size) : 1
    left_range = split_buffer_entry:ac_buffer_size
    right_range = 1:(split_buffer_entry - 1)

    vals = zeros(T, min(mco.n_measurements, mco.autocorrelation_buffer))
    vals[mco.colons..., 1:length(left_range)] = mco.autocorrelation_buffer[mco.colons..., left_range]
    vals[mco.colons..., (length(left_range) + 1):end] = mco.autocorrelation_buffer[mco.colons..., right_range]

    mu = mean(vals, mco.last_dim)
    v = var(vals, mco.last_dim)
    A(k) = 1./v * mean([vals[i] * vals[i + k] - m^2 for i in 1:(length(vals) - 1 - k)])
    tau = 0.

    # Condition from
    # W. Janke et. al. "Monte Carlo Methods in Classical Statistical Physics"
    for k in 1:Int(floor(mco.length(vals) - 1)/2)
        tau += (1 - k / length(vals)) * A(k)
        if abs(A(k)) < 1e-3 && k >= 6 * tau
            break
        end
    end
end


###################################################
# Binning errors
###################################################

function binning_error{T}(t::Array{T}, bin_size=-1)
    N_bins = 1

    if bin_size == -1
        bin_size = 2^Int(floor(0.5 * log2(length(t))))
        N_bins = 2^Int(ceil(0.5 * log2(length(t))))
    else
        N_bins = Int(ceil(length(t) / bin_size))
    end

    t_dims = length(size(t))
    colons = [Colon() for _ in 1:t_dims - 1]
    rnge = collect(1:bin_size)
    bin_array = cat(t_dims, [squeeze(mean(t[colons..., (i - 1) * bin_size + rnge], t_dims), t_dims) for i in 1:N_bins]...)
    return 1./N_bins * var(bin_array, t_dims)
end


function binning_error{T}(mco::monte_carlo_observable{T})
    return 1./(mco.curr_bin - 1) * var(mco.bins[mco.colons..., 1:(mco.curr_bin - 1)], mco.last_dim)
end


###################################################
# Jackknife functions
###################################################

@inline function jackknife_block{T}(k, mco::monte_carlo_observable{T})
    return mean(mco.bins[mco.colons..., collect([1:k; (k + 2):(mco.curr_bin - 1)])], mco.last_dim)
end


@inline function jackknife_blocks{T}(f::Function, k, mcos::Array{monte_carlo_observable{T}, 1})
    blocks = [mco.bins[mco.colons..., collect([1:k; (k + 2):(mco.curr_bin - 1)])] for mco in mcos]
    return mean(f(blocks...), mcos[1].last_dim)
end


function jackknife_error{T}(mco::monte_carlo_observable{T})
    n_blocks = mco.curr_bin - 1
    blocks = cat(mco.last_dim, [jackknife_block(i, mco) for i in 1:n_blocks]...)
    m = mean(blocks, mco.last_dim)
    return (n_blocks - 1) / n_blocks * sum((blocks .- m).^2, mco.last_dim)
end


function jackknife_error{T}(f::Function, mcos::Array{monte_carlo_observable{T}, 1})
    n_blocks = mcos[1].curr_bin - 1
    blocks = cat(mcos[1].last_dim, [jackknife_blocks(f, i, mcos) for i in 1:n_blocks]...)
    m = mean(blocks, mco.last_dim)
    return (n_blocks - 1) / n_blocks * sum((blocks .- m).^2, mco.last_dim)
end

function Base.var{T}(mco::monte_carlo_observable{T})
    return jackknife_error(mco)
end