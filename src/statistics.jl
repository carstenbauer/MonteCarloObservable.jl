# define error estimation tools for Observable{T} type
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
    error(obs::Observable{T})

Estimate of the standard deviation (one-sigma error) of the mean.
Respects correlations between measurements through binning analysis.

Note that this is not the same as `Base.std(timeseries(obs))`, not even
for uncorrelated measurements.

See also [`mean(obs)`](@ref).
"""
function error(obs::Observable{T}) where T
    # choose binsize such that we have at least 32 full bins.
    binning_error(obs, binsize=floor(Int, length(obs)/32))
end
error(obs::Observable, Rvalue::Float64) = sqrt(Rvalue*var(obs)/length(obs))

finderror(obs::Observable) = Rplateaufinder(obs)[1]

function Rplateaufinder(obs::Observable)
    # find start of plateau as first maximum of R, i.e. last R value of
    # initial increase before first decrease.
    # This corresponds to estimating the error as it's first local maximum.
    bss, R = R_function(timeseries(obs), min_nbins=32)
    lastr = R[1]
    conv = false
    for r in R[2:end]
        if r < lastr # first decrease
            conv = true
            break
        end
        lastr = r
    end
    return error(obs, lastr), conv, lastr
end
isconverged(obs::Observable) = Rplateaufinder(obs)[2]

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
tau(obs::Observable{T}, Rvalue::Float64) where T = (Rvalue - 1)/2


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
    println("x ≈ y + ",round(out,4),"·δ")
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
        O[i] = R[i] ? 0.0 : round(a>b ? abs(a-(b+δ))/δ : -abs(a-(b-δ))/δ,4)
      end
      println("A ≈ B + K.*Δ, where K is:")
      display(O)
    else
      warn("Unfortunately print=true is only supported for real input.")
    end
  end

  return allequal
end
