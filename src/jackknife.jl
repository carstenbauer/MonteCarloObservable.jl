# --------------------------------------
#           Jackknife analysis
# --------------------------------------
# for general AbstractArrays
# specifics for Observable type in statistics.jl

"""
    jackknife_error(g::Function, x; [binsize=10])

Computes the jackknife standard deviation of `g(<x>)` by binning
x and performing leave-one-out analysis.
"""
function jackknife_error(g::Function, x::AbstractVector{T}; binsize::Int=10) where T<:Real
    rem(length(x), binsize) == 0 || throw(ArgumentError("Bin size not compatible with sample size"))

    xblock = map(mean, Base.Iterators.partition(x, binsize))
    gis = Jackknife.leaveoneout(g, xblock)
    return sqrt(Jackknife.var(g, xblock; gis=gis))
end

function jackknife_error(g::Function, x::AbstractVector{T}; binsize::Int=10) where T<:Complex
    sqrt(jackknife_error(g, real(x), binsize=binsize)^2 + jackknife_error(g, imag(x), binsize=binsize)^2)
end

function jackknife_error(g::Function, x::AbstractArray{T}; binsize::Int=10) where T<:Number
    ndimsx = ndims(x)
    mapslices(y->binning_error(y; binsize=binsize), x, ndimsx)[(Colon() for _ in 1:ndimsx-1)...,1]
end

# Data: arrays
function jackknife_error(g::Function, x::Union{AbstractArray{<:Number},AbstractVector{T} where T<:AbstractArray{<:Number}}; binsize::Int=10)
    error("Jackknife error calculation for array like data not yet supported.")
end


"""
**Jackknife** errors for functions of uncertain data, i.e. g(<x>)
"""
module Jackknife

# https://github.com/ararslan/Jackknife.jl was useful resource


"""
    leaveoneout(g::Function, x)
Estimate the `g(x)` for each subsample of `x`, systematically
omitting each index one at a time. The result is a vector with the resulting `g(x_[])`.
"""
function leaveoneout(g::Function, x::AbstractVector{T}) where T<:Real
    length(x) > 1 || throw(ArgumentError("The sample must have size > 1"))
    return [g(circshift(x, -i)[2:end]) for i in 0:length(x)-1]
end
# function leaveoneout(g::Function, x::AbstractVector{T}) where T<:Real
#     length(x) > 1 || throw(ArgumentError("The sample must have size > 1"))
#     inds = eachindex(x)
#     return [g(mean(x[filter(j -> j != i, inds)])) for i in inds]
# end


"""
    var(g::Function, x)
Compute the jackknife estimate of the variance of `g(<x>)`, where `g` is given as a
function that computes a point estimate when passed a real-valued vector `x`.
"""
function var(g::Function, x::AbstractVector{T}; gis::AbstractVector{T}=leaveoneout(g, x)) where T<:Real
    n = length(x)
    return Base.var(gis) * (n - 1)^2 / n # Eq. (3.35) in QMC Methods book
end


"""
    bias(g::Function, x)
Compute the jackknife estimate of the bias of `g`, which is given as a
function that computes a point estimate when passed a real-valued vector `x`.
"""
function bias(g::Function, x::AbstractVector{T}; gis::AbstractVector{T}=leaveoneout(g, x)) where T<:Real
    return (length(x) - 1) * (mean(gis) - g(x)) # Basically Eq. (3.33)
end


"""
    estimate(g::Function, x)
Compute the bias-corrected jackknife estimate of the parameter `g(<x>)`.
"""
function estimate(g::Function, x::AbstractVector{T}; gis::AbstractVector{T}=leaveoneout(g, x)) where T<:Real
    n = length(x)
    return n * g(x) - (n - 1) * mean(gis) # Eq. (3.34) in QMC Methods book
end


end # module

export Jackknife
