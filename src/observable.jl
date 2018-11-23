"""
A Markov Chain Monte Carlo observable.
"""
mutable struct Observable{MeasurementType<:Union{Array, Number}, MeanType<:Union{Array, Number}}

    # parameters (external)
    name::String
    alloc::Int
    inmemory::Bool # and maybe dump to HDF5 in the end vs keeping on disk (dumping in chunks)
    outfile::String # format deduced from extension
    HDF5_dset::String # where to put data in HDF5 and JLD case

    # internal
    n_meas::Int # total number of measurements
    elsize::Tuple{Vararg{Int}}
    colons::Vector{Colon}
    n_dims::Int
    timeseries::Vector{MeasurementType}
    tsidx::Int # points to next free slot in timeseries (!= n_meas+1 for inmemory == false)

    mean::MeanType # estimate for mean

    outformat::String

    Observable{T, MT}() where {T, MT} = new()
end







# -------------------------------------------------------------------------
#   Constructor / Initialization
# -------------------------------------------------------------------------
"""
    Observable(t, name; keyargs...)

Create an observable of type `t`.

The following keywords are allowed:

* `alloc`: preallocated size of time series container
* `outfile`: default HDF5/JLD output file for io operations
* `dataset`: target path within `outfile`
* `inmemory`: wether to keep the time series in memory or on disk
* `meantype`: type of the mean (should be compatible with measurement type `t`)

See also [`Observable`](@ref).
"""
function Observable(t::DataType, name::String; alloc::Int=1000, inmemory::Bool=true,
                       outfile::String="Observables.jld", dataset::String=name, meantype::DataType=Type{Union{}})

    # load olf memory dump if !inmemory
    oldfound = false
    if !inmemory && isfile(outfile)
        jldopen(outfile) do f
            HDF5.has(f.plain, dataset) && (oldfound = true)
        end
    end
    oldfound && (return loadobs_frommemory(outfile, dataset))


    # trying to find sensible DataType for mean if not given
    mt = meantype
    if mt == Type{Union{}} # not set
        if eltype(t)<:Real
            mt = ndims(t)>0 ? Array{Float64, ndims(t)} : Float64
        else
            mt = ndims(t)>0 ? Array{ComplexF64, ndims(t)} : ComplexF64
        end
    end

    @assert ndims(t)==ndims(mt)

    obs = Observable{t, mt}()
    obs.name = name
    obs.alloc = alloc
    obs.inmemory = inmemory
    obs.outfile = outfile
    obs.HDF5_dset = dataset

    _init!(obs)
    return obs
end




"""
    _init!(obs)

Initialize non-external fields of observable `obs`.
"""
function _init!(obs::Observable{T}) where T
    # internal
    obs.n_meas = 0
    obs.elsize = (-1,) # will be determined on first add! call
    obs.colons = [Colon() for _ in 1:ndims(T)]
    obs.n_dims = ndims(T)

    obs.tsidx = 1
    obs.timeseries = Vector{T}(undef, obs.alloc) # init with Missing values in Julia 1.0

    if ndims(T) == 0
        obs.mean = convert(T, zero(eltype(T)))
    else
        obs.mean = convert(T, fill(zero(eltype(T)),fill(0, ndims(T))...))
    end

    # figure out outformat
    allowed_ext = ["jld"] # ["h5", "hdf5", "jld", "bin", "csv"]
    try
        ext = fileext(obs.outfile)
        ext in allowed_ext  || error("Unknown outfile extension \"", ext ,"\".")
        obs.outformat = ext
    catch
    end
    nothing
end


"""
    reset!(obs::Observable{T})

Resets all measurement information in `obs`.
"""
reset!(obs::Observable{T}) where T = _init!(obs)









# -------------------------------------------------------------------------
#   Constructor macros
# -------------------------------------------------------------------------
"""
Convenience macro for generating an Observable from a vector of measurements.
"""
macro obs(arg)
    return quote
        # local o = Observable($(esc(eltype))($(esc(arg))), $(esc(string(arg))))
        local o = Observable($(esc(eltype))($(esc(arg))), "observable")
        add!(o, $(esc(arg)))
        o
    end
end

"""
Convenience macro for generating a "disk observable" (`inmemory=false`) from a vector of measurements.
"""
macro diskobs(arg)
    return quote
        # local o = Observable($(esc(eltype))($(esc(arg))), $(esc(string(arg))))
        local o = Observable($(esc(eltype))($(esc(arg))), "observable"; inmemory=false)
        add!(o, $(esc(arg)))
        o
    end
end







# -------------------------------------------------------------------------
#   Basic properties (mostly adding methods to Base functions)
# -------------------------------------------------------------------------
"""
    eltype(obs::Observable{T})

Returns the type `T` of a measurment of the observable.
"""
@inline Base.eltype(obs::Observable{T}) where T = T

"""
Length of observable's time series.
"""
@inline Base.length(obs::Observable{T}) where T = obs.n_meas

"""
Last index of the observable's time series.
"""
@inline Base.lastindex(obs::Observable{T}) where T = length(obs)

"""
Size of the observable (of one measurement).
"""
@inline Base.size(obs::Observable{T}) where T = obs.elsize

"""
Number of dimensions of the observable (of one measurement).

Equivalent to `ndims(T)`.
"""
@inline Base.ndims(obs::Observable{T}) where T = ndims(T)

"""
Returns `true` if the observable hasn't been measured yet.
"""
Base.isempty(obs::Observable{T}) where T = obs.n_meas == 0

"""
    iterate(iter [, state]) -> Tuple{Array{Complex{Float64},1},Int64}

Implementation of Julia's iterator interface
"""
Base.iterate(obs::Observable, state::Int=0) = state+1 <= length(obs) ? (obs[state+1], state+1) : nothing
# TODO: Maybe optimize for disk observables, i.e. load full timeseries in start

"""
Name of the Observable.
"""
name(obs::Observable{T}) where T = obs.name

"""
    rename(obs::Observable, name)

Renames the observable.
"""
rename(obs::Observable{T}, name::AbstractString) where T = begin obs.name = name; nothing end

"""
Checks wether the observable is kept in memory (vs. on disk).
"""
inmemory(obs::Observable{T}) where T = obs.inmemory

"""
Checks wether the observable is kept in memory (vs. on disk).
"""
isinmemory(obs::Observable) = obs.inmemory

"""
Check if two observables have equal timeseries.
"""
function ==(a::Observable, b::Observable)
    timeseries(a) == timeseries(b)
end






# -------------------------------------------------------------------------
#   Cosmetics: Base.show, Base.summary
# -------------------------------------------------------------------------
function _println_header(io::IO, obs::Observable{T}) where T
    sizestr = ""
    if length(obs) > 0 
        if ndims(T) == 0
            nothing
        elseif ndims(T) == 1
            @inbounds sizestr = "$(size(obs)[1])-element "
        else
            sizestr = string(join(size(obs), "x"), " ")
        end
    end
    # disk = inmemory(obs) ? "" : "Disk-"
    println(io, "$(sizestr)$(T) Observable")
    nothing
end

function _println_body(io::IO, obs::Observable{T}) where T
    println("| Name: ", name(obs))
    !inmemory(obs) && print("| In Memory: ", false,"\n")
    print("| Measurements: ", length(obs))
    if length(obs) > 0
        ndims(obs) == 0 && print("\n| Mean: ", mean(obs))
    end
end

Base.show(io::IO, obs::Observable{T}) where T = begin
    _println_header(io, obs)
    _println_body(io, obs)
    nothing
end
Base.show(io::IO, m::MIME"text/plain", obs::Observable{T}) where T = print(io, obs)

Base.summary(io::IO, obs::Observable{T}) where T = _println_header(io, obs)
Base.summary(obs::Observable{T}) where T = summary(stdout, obs)










# -------------------------------------------------------------------------
#   add! and push!
# -------------------------------------------------------------------------
"""
Add measurements to an observable.

    add!(obs::Observable{T}, measurement::T; verbose=false)
    add!(obs::Observable{T}, measurements::AbstractVector{T}; verbose=false)

"""
function add!(obs::Observable) end

"""
Add measurements to an observable.

    push!(obs::Observable{T}, measurement::T; verbose=false)
    push!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false)

Note that because of internal preallocation this isn't really a push.
"""
function push!(obs::Observable) end




# interface
add!(obs::Observable{T}, measurement::T; kwargs...) where {T<:Number} = _add!(obs, measurement; kwargs...)
add!(obs::Observable{T}, measurement::T; kwargs...) where {T<:AbstractArray} = _add!(obs, measurement; kwargs...)
function add!(obs::Observable{T}, measurements::AbstractVector{T}; kwargs...) where T
    @inbounds for i in eachindex(measurements)
        _add!(obs, measurements[i]; kwargs...)
    end
end
function add!(obs::Observable{T}, measurements::AbstractArray{S, N}; kwargs...) where {T,S,N}
    S === eltype(T) || throw(TypeError(:add!, "", AbstractArray{eltype(T)}, AbstractArray{S})) # TODO: check if S is subtype of T
    N == obs.n_dims + 1 || throw(DimensionMismatch("Dimensions of given measurements ($(N-1)) don't match observable's dimensions ($(obs.n_dims))."))
    length(obs) == 0 || size(measurements)[1:N-1] == obs.elsize || error("Sizes of measurements don't match observable size.")

    @inbounds for i in Base.axes(measurements, ndims(measurements))
        _add!(obs, measurements[.., i]; kwargs...)
    end
end

Base.push!(obs::Observable{T}, measurement::T; kwargs...) where T = add!(obs, measurement; kwargs...)
Base.push!(obs::Observable{T}, measurements::AbstractArray; kwargs...) where T = add!(obs, measurements; kwargs...)



# implementation
@inline function _add!(obs::Observable{T}, measurement::T; verbose=false) where T
    if obs.elsize == (-1,) # first add
        obs.elsize = size(measurement)
        obs.mean = zero(measurement)
    end

    size(measurement) == obs.elsize || error("Measurement size != observable size")

    # update mean estimate
    verbose && println("Updating mean estimate.")
    obs.mean = (obs.n_meas * obs.mean + measurement) / (obs.n_meas + 1)
    obs.n_meas += 1

    # add to time series
    verbose && println("Adding measurment to time series [chunk].")
    obs.timeseries[obs.tsidx] = copy(measurement)
    obs.tsidx += 1

    if obs.tsidx == length(obs.timeseries)+1 # next add! would overflow
        verbose && println("Handling time series [chunk] overflow.")
        if obs.inmemory
            verbose && println("Increasing time series size.")
            tslength = length(obs.timeseries)
            new_timeseries = Vector{T}(undef, tslength + obs.alloc)
            new_timeseries[1:tslength] = obs.timeseries
            obs.timeseries = new_timeseries
        else
            verbose && println("Dumping time series chunk to disk.")
            updateondisk(obs)
            verbose && println("Setting time series index to 1.")
            obs.tsidx = 1
        end
    end
    verbose && println("Done.")
    nothing
end











# -------------------------------------------------------------------------
#   getindex, view, and timeseries access
# -------------------------------------------------------------------------
"""
Returns the time series of the observable.

If `isinmemory(obs) == false` it will read the time series from disk.

See also [`getindex`](@ref) and [`view`](@ref).
"""
timeseries(obs::Observable{T}) where T = obs[1:end]
ts(obs::Observable) = timeseries(obs)



# interface
"""
    view(obs::Observable{T}, args...)

Get, if possible, a view into the time series of the observable.
"""
function Base.view(obs::Observable) end

"""
    getindex(obs::Observable{T}, args...)

Get an element of the time series of the observable.
"""
function Base.getindex(obs::Observable) end




# implementation
function Base.getindex(obs::Observable{T}, idx::Int) where T
    1 <= idx <= length(obs) || throw(BoundsError(typeof(obs), idx))
    if obs.inmemory
        return getindex(obs.timeseries, idx)
    else
        return getindex_fromfile(obs, idx)
    end
end
function Base.getindex(obs::Observable{T}, rng::UnitRange{Int}) where T
    rng.start >= 1 && rng.stop <= length(obs) || throw(BoundsError(typeof(obs), rng))
    if obs.inmemory
        return getindex(obs.timeseries, rng)
    else
        return getindexrange_fromfile(obs, rng)
    end
end
Base.getindex(obs::Observable, c::Colon) = getindex(obs, 1:length(obs))


function Base.view(obs::Observable{T}, idx::Int) where T
    1 <= idx <= length(obs) || throw(BoundsError(typeof(obs), idx))
    if obs.inmemory
        view(obs.timeseries, idx)
    else
        error("Only supported for `inmemory(obs) == true`. Alternatively, load the timeseries as an array (e.g. with timeseries_frommemory_flat) and use views into this array.");
    end
end
function Base.view(obs::Observable{T}, rng::UnitRange{Int}) where T
    rng.start >= 1 && rng.stop <= length(obs) || throw(BoundsError(typeof(obs), rng))
    if obs.inmemory
        view(obs.timeseries, rng)
    else
        error("Only supported for `inmemory(obs) == true`. Alternatively, load the timeseries as an array (e.g. with timeseries_frommemory_flat) and use views into this array.");
    end
end
Base.view(obs::Observable, c::Colon) = view(obs, 1:length(obs))


















# -------------------------------------------------------------------------
#   Basic Statistics
# -------------------------------------------------------------------------
"""
Mean of the observable's time series.
"""
mean(obs::Observable{T}) where T = length(obs) > 0 ? obs.mean : error("Can't calculate mean of empty observable.")

"""
Standard deviation of the observable's time series (assuming uncorrelated data).

See also [`mean(obs)`](@ref), [`var(obs)`](@ref), and [`error(obs)`](@ref).
"""
std(obs::Observable{T}) where T = length(obs) > 0 ? std(timeseries(obs)) : error("Can't calculate std of empty observable.")

"""
Variance of the observable's time series (assuming uncorrelated data).

See also [`mean(obs)`](@ref), [`std(obs)`](@ref), and [`error(obs)`](@ref).
"""
var(obs::Observable{T}) where T = length(obs) > 0 ? var(timeseries(obs)) : error("Can't calculate variance of empty observable.")







# -------------------------------------------------------------------------
#   Statistics: error estimation
# -------------------------------------------------------------------------
"""
Estimate of the one-sigma error of the observable's mean.
Respects correlations between measurements through binning analysis.

Note that this is not the same as `Base.std(timeseries(obs))`, not even
for uncorrelated measurements.

See also [`mean(obs)`](@ref).
"""
error(obs::Observable) = binning_error(timeseries(obs))
error(obs::Observable, binsize::Int) = binning_error(timeseries(obs), binsize)

"""
Returns one sigma error and convergence flag (don't trust it!).
"""
error_with_convergence(obs::Observable) = binning_error_with_convergence(timeseries(obs))

"""
Estimate of the one-sigma error of the observable's mean.
Respects correlations between measurements through binning analysis.

Strategy: just take largest R value considering an upper limit for bin size (min_nbins)
"""
error_naive(obs::Observable{T}) where T = binning_error_naive(timeseries(obs))






"""
Integrated autocorrelation time (obtained by binning analysis).

See also [`error(obs)`](@ref).
"""
tau(obs::Observable{T}) where T = 0.5*(error(obs)^2 * length(obs) / var(obs) .- 1)
tau(obs::Observable{T}, Rvalue::Float64) where T = tau(Rvalue)
tau(Rvalue::Float64) = (Rvalue - 1)/2
tau(ts::AbstractArray) = 0.5*(binning_error(ts)^2 * length(ts) / var(ts) .- 1)







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