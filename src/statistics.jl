using ErrorAnalysis

function Base.mean{T}(mco::Observable{T}) where T
    return mean(mco.bins[mco.colons..., 1:(mco.curr_bin - 1)], mco.last_dim)
end

function Base.var{T}(mco::Observable{T}) where T
    return jackknife_error(mco)
end

# integrated autocorrelation time
# TODO: Any advantage of peters manual implementation over the simple StatsBase version in ErrorAnalysis?

# binning_error
# function binning_error{T}(mco::Observable{T})
#     return 1./(mco.curr_bin - 1) * var(mco.bins[mco.colons..., 1:(mco.curr_bin - 1)], mco.last_dim)
# end



# jackknife_error
# @inline function jackknife_block{T}(k, mco::Observable{T})
#     return mean(mco.bins[mco.colons..., collect([1:k; (k + 2):(mco.curr_bin - 1)])], mco.last_dim)
# end


# @inline function jackknife_blocks{T}(f::Function, k, mcos::Array{Observable{T}, 1})
#     blocks = [mco.bins[mco.colons..., collect([1:k; (k + 2):(mco.curr_bin - 1)])] for mco in mcos]
#     return mean(f(blocks...), mcos[1].last_dim)
# end


# function jackknife_error{T}(mco::Observable{T})
#     n_blocks = mco.curr_bin - 1
#     blocks = cat(mco.last_dim, [jackknife_block(i, mco) for i in 1:n_blocks]...)
#     m = mean(blocks, mco.last_dim)
#     return (n_blocks - 1) / n_blocks * sum((blocks .- m).^2, mco.last_dim)
# end


# function jackknife_error{T}(f::Function, mcos::Array{Observable{T}, 1})
#     n_blocks = mcos[1].curr_bin - 1
#     blocks = cat(mcos[1].last_dim, [jackknife_blocks(f, i, mcos) for i in 1:n_blocks]...)
#     m = mean(blocks, mco.last_dim)
#     return (n_blocks - 1) / n_blocks * sum((blocks .- m).^2, mco.last_dim)
# end