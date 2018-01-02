# define ErrorAnalysis tools for Observable{T} type
"""
    binning_error(obs::Observable{T}[; binsize=0, warnings=false])

Calculates statistical one-sigma error (eff. standard deviation) for correlated data.
How: Binning of data and assuming statistical independence of bins
(i.e. R plateau has been reached). (Eq. 3.18 of Book basically)

The default `binsize=0` indicates automatic binning.
"""
binning_error(obs::Observable{T}, args...; keyws...) where T = binning_error(timeseries(obs), args...; keyws...)

"""
    jackknife_error(g::Function, obs::Observable{T}; [binsize=10])

Computes the jackknife standard deviation of `g(<obs>)` by binning
the observable's time series and performing leave-one-out analysis.
"""
jackknife_error(g::Function, obs::Observable{T}, args...; keyws...) where T = jackknife_error(g, timeseries(obs), args...; keyws...)

"""
    mean(obs::Observable{T})

Estimate of the mean of the observable.
"""
mean(obs::Observable{T}) where T = obs.mean

"""
    std(obs::Observable{T})

Estimate of the standard deviation (one-sigma error) of the mean.
Respects correlations between measurements through binning analysis.

Note that this is not the same as `Base.std(timeseries(obs))`, not even 
for uncorrelated measurements.

Corresponds to the square root of [`var(obs)`](@ref). See also [`mean(obs)`](@ref).
"""
function std(obs::Observable{T}) where T
    # choose binsize such that we have at least 32 full bins.
    binning_error(obs, binsize=floor(Int, length(obs)/32))
end

"""
    var(obs::Observable{T})

Estimate of the variance of the mean.
Respects correlations between measurements through binning analysis.

Note that this is not the same as `Base.var(timeseries(obs))`, not even 
for uncorrelated measurements.

Corresponds to the square of [`std(obs)`](@ref). See also [`mean(obs)`](@ref).
"""
var(obs::Observable{T}) where T = std(obs)^2