# add measurements
"""
    add!(obs::Observable{T}, measurement::T; verbose=false)

Add a `measurement` to observable `obs`.
"""
function add!(obs::Observable{T}, measurement::T; verbose=false) where T
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

"""
    add!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false)

Add multiple `measurements` to observable `obs`.
"""
function add!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false) where T
    # OPT: if length(measurements) > alloc we should avoid multiple reallocations
    @inbounds for i in eachindex(measurements)
        add!(obs, measurements[i]; verbose=verbose)
    end
end

# push! === add! mappings
"""
    push!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false)

Add multiple `measurements` to observable `obs`.
Note that because of preallocation this isn't really a push.
"""
Base.push!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false) where T = add!(obs, measurements; verbose=verbose)


"""
    push!(obs::Observable{T}, measurement::T; verbose=false)

Add a `measurement` to observable `obs`.
Note that because of preallocation this isn't really a push.
"""
Base.push!(obs::Observable{T}, measurement::T; verbose=false) where T = add!(obs, measurement; verbose=verbose)


# extract information
"""
    timeseries(obs::Observable{T})

Returns the measurement time series of an observable.

If `inmemory(obs) == false` it will read the time series from disk and thus might take some time.

See also [`getindex`](@ref) and [`view`](@ref).
"""
timeseries(obs::Observable{T}) where T = obs[1:end]
ts(obs::Observable) = timeseries(obs)


# clear! == reset! mappings
"""
    clear!(obs::Observable{T})

Clears all measurement information in `obs`.
Identical to [`reset!`](@ref).
"""
clear!(obs::Observable{T}) where T = init!(obs)

"""
    reset!(obs::Observable{T})

Resets all measurement information in `obs`.
Identical to [`clear!`](@ref).
"""
reset!(obs::Observable{T}) where T = init!(obs)


# implementing Base functions
"""
    eltype(obs::Observable{T})

Returns the type `T` of a measurment of the observable.
"""
@inline Base.eltype(obs::Observable{T}) where T = T

"""
    length(obs::Observable{T})

Number of measurements of the observable.
"""
@inline Base.length(obs::Observable{T}) where T = obs.n_meas
@inline Base.lastindex(obs::Observable{T}) where T = length(obs)

"""
    size(obs::Observable{T})

Size of the observable (of one measurement).
"""
@inline Base.size(obs::Observable{T}) where T = obs.elsize

"""
    ndims(obs::Observable{T})

Number of dimensions of the observable (of one measurement).

Equivalent to `ndims(T)`.
"""
@inline Base.ndims(obs::Observable{T}) where T = ndims(T)

"""
    getindex(obs::Observable{T}, args...)

Get an element of the measurement time series of the observable.
"""
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

"""
    view(obs::Observable{T}, args...)

Get a view into the measurement time series of the observable.
"""
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

"""
    isempty(obs::Observable{T})

Determine wether the observable hasn't been measured yet.
"""
Base.isempty(obs::Observable{T}) where T = obs.n_meas == 0

# iteration interface implementation
# TODO: load timeseries in start (in case it is loaded from disk)
Base.iterate(obs::Observable, state::Int=0) = state+1 <= length(obs) ? (obs[state+1], state+1) : nothing


# display, show, print magic
# Base.summary(obs::Observable{T}) where T = "Observable{$(isempty(obs.elsize) ? "" : string(join(size(obs), "x")*" "))$(T)}"
Base.summary(obs::Observable{T}) where T = "Observable \"$(obs.name)\" of type $((obs.elsize == (-1,)) ? "" : string(join(size(obs), "x")*" "))$(T) with $(length(obs)) measurement$(length(obs) != 1 ? "s" : "")"
Base.show(io::IO, obs::Observable{T}) where T = print(io, summary(obs))
Base.show(io::IO, m::MIME"text/plain", obs::Observable{T}) where T = print(io, summary(obs))
# Base.show(io::IO, obs::Observable{T}) where T = (println(io, summary(obs));Base.showarray(io, obs.timeseries[1:obs.n_meas], true; header=false))
# Base.show(io::IO, m::MIME"text/plain", obs::Observable{T}) where T = (println(io, summary(obs));Base.showarray(io,obs.timeseries[1:obs.n_meas], false; header=false))


# Base.similar(obs::Observable{T}) where T = Observable(T, )
# Base.similar(obs::Observable{T}, name::AbstractString) where T = Observable(T, name)

"""
    rename(obs::Observable{T}, name)

Renames the observable.
"""
rename(obs::Observable{T}, name::AbstractString) where T = begin obs.name = name; nothing end

"""
    name(obs::Observable{T})

Returns the name of the observable.
"""
name(obs::Observable{T}) where T = obs.name

"""
    inmemory(obs::Observable{T})

Checks wether the observable is kept in memory (vs. on disk).
"""
inmemory(obs::Observable{T}) where T = obs.inmemory


function ==(a::Observable, b::Observable)
    timeseries(a) == timeseries(b)
end

# function ==(a::Observable, b::Observable)
#     T == S || (return false)

#     for f in fieldnames(a)
#         f == :timeseries || getfield(a, f) == getfield(b, f) || (return false)
#         # compare only non (basically) zero part of timeseries array
#         f == :timeseries && (timeseries(a) == timeseries(b) || (return false))
#     end

#     return true
# end