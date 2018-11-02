# define error estimation tools for Observable{T} type
"""
    jackknife_error(g::Function, obs1, ob2, ...)

Computes the jackknife one sigma error of `g(<obs1>, <obs2>, ...)` by performing 
a "leave-one-out" analysis.

The function `g(x)` must take one matrix argument `x`, whose columns correspond 
to the time series of the observables, and produce a scalar (point estimate).

Example:

`g(x) = @views mean(x[:,1])^2 - mean(x[:,2].^2)` followed by `jackknife_error(g, obs1, obs2)`.
Here `x[:,1]` is basically `timeseries(obs1)` and `x[:,2]` is `timeseries(obs2)`.
"""
jackknife_error(g::Function, obs::Observable{T}) where T = Jackknife.error(g, timeseries(obs))
jackknife_error(g::Function, obss::Observable{T}...) where T = Jackknife.error(g, hcat(timeseries.(obss)...))


"""
    mean(obs::Observable{T})

Estimate of the mean of the observable.
"""
mean(obs::Observable{T}) where T = obs.mean

"""
    error(obs::Observable{T})

Estimate of the one-sigma error of the observable's mean.
Respects correlations between measurements through binning analysis.

Note that this is not the same as `Base.std(timeseries(obs))`, not even
for uncorrelated measurements.

See also [`mean(obs)`](@ref).
"""
error(obs::Observable) = binning_error(timeseries(obs))
error(obs::Observable, binsize::Int) = binning_error(timeseries(obs), binsize)

"""
Returns one sigma error and convergence flag (boolean).
"""
error_with_convergence(obs::Observable) = binning_error_with_convergence(timeseries(obs))

# """
#   isconverged(obs)

# Checks if the estimation of the one sigma error is converged.

# Returns `true` once the mean `R` value is converged up to 0.1% accuracy.
# This corresponds to convergence of the error itself up to ~3% (sqrt).
# """
# isconverged(obs::Observable) = isconverged(timeseries(obs))

"""
    error_naive(obs::Observable{T})

Estimate of the one-sigma error of the observable's mean.
Respects correlations between measurements through binning analysis.

Strategy: just take largest R value considering an upper limit for bin size (min_nbins)
"""
error_naive(obs::Observable{T}) where T = binning_error_naive(timeseries(obs))

"""
    std(obs::Observable{T})

Standard deviation of the time series (assuming uncorrelated data).

See also [`mean(obs)`](@ref), [`var(obs)`](@ref), and [`error(obs)`](@ref).
"""
std(obs::Observable{T}) where T = std(timeseries(obs))

"""
    var(obs::Observable{T})

Variance of the time series (assuming uncorrelated data).

See also [`mean(obs)`](@ref), [`std(obs)`](@ref), and [`error(obs)`](@ref).
"""
var(obs::Observable{T}) where T = var(timeseries(obs))

"""
    tau(obs::Observable{T})

Integrated autocorrelation time (obtained by binning analysis).

See also [`error(obs)`](@ref).
"""
tau(obs::Observable{T}) where T = 0.5*(error(obs)^2 * length(obs) / var(obs) - 1)
tau(obs::Observable{T}, Rvalue::Float64) where T = tau(Rvalue)
tau(Rvalue::Float64) = (Rvalue - 1)/2
tau(ts::AbstractArray) = 0.5*(binning_error(ts)^2 * length(ts) / var(ts) - 1)

"""
    iswithinerrorbars(a, b, δ[, print=false])

Checks whether numbers `a` and `b` are equal up to given error `δ`.
Will print `x ≈ y + k·δ` for `print=true`.

Is equivalent to `isapprox(a,b,atol=δ,rtol=zero(b))`.
"""
function iswithinerrorbars(a::T, b::S, δ::Real, print::Bool=false) where T<:Number where S<:Number
  equal = isapprox(a,b,atol=δ,rtol=zero(δ))
  if print && !equal
    out = a>b ? abs(a-(b+δ))/δ : -abs(a-(b-δ))/δ
    println("x ≈ y + ",round(out, digits=4),"·δ")
  end
  return equal
end

"""
    iswithinerrorbars(A::AbstractArray{T<:Number}, B::AbstractArray{T<:Number}, Δ::AbstractArray{<:Real}[, print=false])

Elementwise check whether `A` and `B` are equal up to given real error matrix `Δ`.
Will print `A ≈ B + K.*Δ` for `print=true`.
"""
function iswithinerrorbars(A::AbstractArray{T}, B::AbstractArray{S},
                           Δ::AbstractArray{<:Real}, print::Bool=false) where T<:Number where S<:Number
  size(A) == size(B) == size(Δ) || error("A, B and Δ must have same size.")

  R = iswithinerrorbars.(A,B,Δ,false)
  allequal = all(R)

  if print && !all(R)
    if T<:Real && S<:Real
      O = similar(A, promote_type(T,S))
      for i in eachindex(O)
        a = A[i]; b = B[i]; δ = Δ[i]
        O[i] = R[i] ? 0.0 : round(a>b ? abs(a-(b+δ))/δ : -abs(a-(b-δ))/δ, digits=4)
      end
      println("A ≈ B + K.*Δ, where K is:")
      display(O)
    else
      @warn "Unfortunately print=true is only supported for real input."
    end
  end

  return allequal
end

iswithinerrorbars(A::Observable, B::Observable, Δ, print=false) = iswithinerrorbars(timeseries(A), timeseries(B), Δ, print)