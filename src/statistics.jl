using ErrorAnalysis

import ErrorAnalysis.binning_error
import ErrorAnalysis.jackknife_error

# define ErrorAnalysis tools for Observable{T} type
binning_error(obs::Observable{T}, args...; keyws...) where T = binning_error(timeseries(obs), args...; keyws...)
jackknife_error(g::Function, obs::Observable{T}, args...; keyws...) where T = jackknife_error(g, timeseries(obs), args...; keyws...)
# TODO integrated autocorrelation

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
std(obs::Observable{T}) where T = binning_error(obs, binsize=10)
# This is of course stupid! Base binsize on integrated autocorrelation.

"""
    var(obs::Observable{T})

Estimate of the variance of the mean.
Respects correlations between measurements through binning analysis.

Note that this is not the same as `Base.var(timeseries(obs))`, not even 
for uncorrelated measurements.

Corresponds to the square of [`std(obs)`](@ref). See also [`mean(obs)`](@ref).
"""
var(obs::Observable{T}) where T = std(obs)^2