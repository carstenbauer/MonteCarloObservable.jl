# --------------------------------------
#           Binning analysis
# --------------------------------------
# for general AbstractArrays
# specifics for Observable type in statistics.jl

"""
    binning_error(X[; binsize=0, warnings=false])

Calculates statistical one-sigma error for correlated data.
How: Binning of data and assuming statistical independence of bins
(i.e. R plateau has been reached). (Eq. 3.18 basically)

The default `binsize=0` indicates automatic binning.
"""
function binning_error(X::AbstractVector{T}; binsize=0, warnings=false) where T<:Real
    # Data: real numbers
    if binsize == 0
        binsize = floor(Int, length(X)/32)
        binsize = binsize==0?1:binsize
    end

    isinteger(length(X) / binsize) || !warnings ||
        warn("Non-integer number of bins $(length(X) / binsize). " *
             "Last bin will be smaller than all others.")

    bin_means = map(mean, Iterators.partition(X, binsize))
    return sqrt(1/length(bin_means) * var(bin_means))
end
function binning_error(X::AbstractVector{T}; binsize=0, warnings=false) where T<:Complex
    # Data: complex numbers
    sqrt(binning_error(real(X), binsize=binsize, warnings=warnings)^2 +
        binning_error(imag(X), binsize=binsize, warnings=warnings)^2)
end

# Data: arrays
function binning_error(X::AbstractArray{T}; binsize=0, warnings=false) where T<:Number
    ndimsX = ndims(X)
    mapslices(y->binning_error(y; binsize=binsize, warnings=warnings), X, ndimsX)[(Colon() for _ in 1:ndimsX-1)...,1]
end
function binning_error(X::AbstractVector{T}; binsize=0, warnings=false) where T<:(AbstractArray{S} where S)
    binning_error(cat(ndims(X[1])+1, X...); binsize=binsize, warnings=warnings)
end


#####
# Calculation of error coefficient (function) R. (Ch. 3.4 in QMC book)
#####
"""
Groups datapoints in bins of varying size `bs`.
Returns the used binsizes `bss` and the error coefficient function `R(bss)` (Eq. 3.20) which should feature
a plateau, i.e. `R(bs_p) ~ R(bs)` for `bs >= bs_p`. (Fig. 3.3)

Optional keyword `min_nbins`. Only bin sizes used that lead to at least `min_nbins` bins.
"""
function R_function(X::AbstractVector{T}; min_nbins=10) where T<:Real
    bss = Int[]
    N = length(X)
    Xmean = mean(X)
    Xvar = var(X)

    for bs in 1:N # TODO: intermediate bin sizes (throw away last unfilled bin)
        N%bs == 0 ? push!(bss, bs) : nothing
    end

    n_bins = Int.(N./bss)
    bss = bss[n_bins .>= min_nbins] # at least min_nbins bins for every binsize

    R = zeros(length(bss))
    for (i, bs) in enumerate(bss)

        blockmeans = vec(mean(reshape(X, (bs,n_bins[i])), 1))

        blocksigma2 = 1/(n_bins[i]-1)*sum((blockmeans - Xmean).^2)

        R[i] = bs * blocksigma2 / Xvar
    end

    return bss, R
end

"""
Groups datapoints in bins of fixed binsize and returns error coefficient R. (Eq. 3.20)
"""
function R_value(X::AbstractVector{T}, binsize::Int) where T<:Real
    N = length(X)
    n_bins = div(N,binsize)
    lastbs = rem(N,binsize)
    lastbs == 0 || (lastbs >= binsize/2 || warn("Binsize leads to last bin having less than binsize/2 elements."))


    blockmeans = vec(mean(reshape(X[1:n_bins*binsize], (binsize,n_bins)), 1))
    if lastbs != 0
        vcat(blockmeans, mean(X[n_bins*binsize+1:end]))
        n_bins += 1
    end

    blocksigma2 = 1/(n_bins-1)*sum((blockmeans - mean(X)).^2)
    return binsize * blocksigma2 / var(X)
end
