# add measurements
"""
    add!(obs::Observable{T}, measurement::T; verbose=false)

Add a `measurement` to observable `obs`.
"""
function add!(obs::Observable{T}, measurement::T; verbose=false) where T
    if isempty(obs.elsize) # first add
        obs.elsize = size(measurement)
        obs.mean = zero(measurement)
    end

    size(measurement) == obs.elsize || error("Measurement size != observable size")

    # update mean estimate
    verbose && println("Updating mean estimate.")
    obs.mean = (obs.n_meas * obs.mean + measurement) / (obs.n_meas + 1)
    obs.n_meas += 1

    # add to timeseries
    verbose && println("Adding measurment to timeseries [chunk].")
    obs.timeseries[obs.tsidx] = measurement
    obs.tsidx += 1
    
    if obs.tsidx == length(obs.timeseries)+1 # next add! would overflow 
        verbose && println("Handling timeseries [chunk] overflow.")
        if obs.keep_in_memory
            verbose && println("Increasing timeseries size.")
            tslength = length(obs.timeseries)
            new_timeseries = Vector{T}(tslength + obs.prealloc)
            new_timeseries[1:tslength] = obs.timeseries
            obs.timeseries = new_timeseries
        else
            verbose && println("Dumping timeseries chunk to disk.")
            # TODO
            verbose && println("Setting timeseries index to 1.")
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
    # OPT: if length(measurements) > prealloc or buffersize we should avoid multiple reallocations
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

Returns the measurement timeseries of an observable.

If `keep_in_memory == false` it will read the timeseries from disk and thus might take some time.

See also [`getindex`](@ref) and [`view`](@ref).
"""
timeseries(obs::Observable{T}) where T = obs[1:end]


# init! == clear! == reset! mappings
"""
    clear!(obs::Observable{T})

Clears all measurement information in `obs`.
Identical to [`init!`](@ref) and [`reset!`](@ref).
"""
clear!(obs::Observable{T}) where T = init!(obs)

"""
    reset!(obs::Observable{T})

Resets all measurement information in `obs`.
Identical to [`init!`](@ref) and [`clear!`](@ref).
"""
reset!(obs::Observable{T}) where T = init!(obs)


# implementing Base functions
"""
    eltype(obs::Observable{T})

Returns the type `T` of a measurment of the observable.
"""
Base.eltype(obs::Observable{T}) where T = T

"""
    length(obs::Observable{T})

Number of measurements of the observable.
"""
Base.length(obs::Observable{T}) where T = obs.n_meas
Base.endof(obs::Observable{T}) where T = length(obs)

"""
    size(obs::Observable{T})

Size of the observable (of one measurement).
"""
Base.size(obs::Observable{T}) where T = obs.elsize

"""
    ndims(obs::Observable{T})

Number of dimensions of the observable (of one measurement).

Equivalent to `ndims(T)`.
"""
Base.ndims(obs::Observable{T}) where T = ndims(T)

"""
    getindex(obs::Observable{T}, args...)

Get an element of the measurement timeseries of the observable.
"""
function Base.getindex(obs::Observable{T}, args...) where T
    if obs.keep_in_memory
        return getindex(view(obs.timeseries, 1:obs.n_meas), args...)
    else
        return getindex_fromfile(obs, args...)
    end
end

"""
    view(obs::Observable{T}, args...)

Get a view into the measurement timeseries of the observable.
"""
function Base.view(obs::Observable{T}, args...) where T
    if obs.keep_in_memory
        view(view(obs.timeseries, 1:obs.n_meas), args...)
    else
        error("Only supported for `keep_in_memory == true`.");
        # TODO: type unstable?
    end
end

"""
    isempty(obs::Observable{T})

Determine wether the observable hasn't been measured yet.
"""
Base.isempty(obs::Observable{T}) where T = obs.n_meas == 0

# iteration interface implementation
# TODO: load timeseries in start (in case it is loaded from disk)
# function Base.start(mco::Observable) state = 1 end
# function Base.done(mco::Observable, state::Int) return state == mco.curr_bin end
# function Base.next(mco::Observable, state::Int)
#     return mco.bins[mco.colons..., state], state + 1
# end


# display, show, print magic
# Base.summary(obs::Observable{T}) where T = "Observable{$(isempty(obs.elsize) ? "" : string(join(size(obs), "x")*" "))$(T)}"
Base.summary(obs::Observable{T}) where T = "Observable of type $(isempty(obs.elsize) ? "" : string(join(size(obs), "x")*" "))$(T) with $(length(obs)) measurement$(length(obs)!=1?"s":"")"
Base.show(io::IO, obs::Observable{T}) where T = print(io, summary(obs))
Base.show(io::IO, m::MIME"text/plain", obs::Observable{T}) where T = print(io, summary(obs))
# Base.show(io::IO, obs::Observable{T}) where T = (println(io, summary(obs));Base.showarray(io, obs.timeseries[1:obs.n_meas], true; header=false))
# Base.show(io::IO, m::MIME"text/plain", obs::Observable{T}) where T = (println(io, summary(obs));Base.showarray(io,obs.timeseries[1:obs.n_meas], false; header=false))