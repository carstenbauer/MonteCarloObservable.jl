# add measurements
"""
    add!(obs::Observable{T}, measurement::T; verbose=false)

Add a `measurement` to observable `obs`.
"""
function add!(obs::Observable{T}, measurement::T; verbose=false) where T
    obs.elsize == () && obs.elsize = size(measurement)
    size(measurement) == obs.elsize || error("Measurement size != observable size")

    # update mean estimate
    obs.mean = (obs.n_meas * obs.mean + measurement) / (obs.n_meas + 1)
    obs.n_meas += 1

    # add to buffer
    if obs.buffer_needed
        obs.buffer[obs.bidx] = measurement
        obs.bidx += 1
        
        if obs.bidx == length(buffer)+1 # overflow
            if obs.keep_timeseries && !obs.keep_in_memory
                # dump buffer chunk to file
                # reset buffer
            end

            if obs.estimate_error
                # calculate error somehow
            end

            obs.bidx = 1
        end
    end

    # add to timeseries
    if ts_needed 
        obs.timeseries[obs.n_meas] = measurement
        
        if obs.n_meas+1 == length(obs.timeseries)+1 # overflow
            tslength = length(obs.timeseries)
            new_timeseries = Vector{T}(tslength + obs.prealloc)
            new_timeseries[1:tslength] = obs.timeseries
            obs.timeseries = new_timeseries
        end
    end
end

"""
    add!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false)

Add multiple `measurements` to observable `obs`.
"""
function add!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false) where T
    # OPT: if length(measurements) > prealloc or buffersize we should avoid multiple reallocations
    @inbounds for i in eachindex(measurements) push!(obs, measurements[i]; verbose) end
end

# push! === add! mappings
"""
    push!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false)

Add multiple `measurements` to observable `obs`.
Note that because of preallocation this isn't really a push.
"""
Base.push!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false) where T = add!(obs, measurements; verbose)


"""
    push!(obs::Observable{T}, measurement::T; verbose=false)

Add a `measurement` to observable `obs`.
Note that because of preallocation this isn't really a push.
"""
Base.push!(obs::Observable{T}, measurement::T; verbose=false) where T = add!(obs, measurement; verbose)


# extract information
"""
    timeseries(obs::Observable{T})

Returns the timeseries of this observable if available (`keep_timeseries == true`).
If `keep_in_memory == false` it will read the timeseries from HDF5 file.
"""
function timeseries(obs::Observable{T})
    # obs.keep_timeseries || error("No timeseries for this observable (`keep_timeseries == false`).")

    if obs.keep_in_memory
        # do not return a view here to be consistent with hdf5 case
        return obs.timeseries = obs.timeseries[1:n_meas]
    else
        # read ts from hdf file
        return obs.timeseries
    end
end


# init! == clear! == reset! mappings
"""
    clear!(obs::Observable{T})

Clears all measurement information in `obs`.
Identical to [init!](@ref) and [reset!](@ref).
"""
clear!(obs::Observable{T}) where T = init!(obs)

"""
    reset!(obs::Observable{T})

Resets all measurement information in `obs`.
Identical to [init!](@ref) and [clear!](@ref).
"""
reset!(obs::Observable{T}) where T = init!(obs)


# implementing Base functions
"""
    eltype(obs::Observable{T})

Returns the type `T` of a measurment of the observable.
"""
Base.eltype(obs:Observable{T}) where T = T

"""
    length(obs::Observable{T})

Number of measurements of the observable.
"""
Base.length(obs::Observable{T}) where T = obs.n_meas

"""
    getindex(obs::Observable{T}, args...)

Get an element of the timeseries of the observable (if available).
"""
Base.getindex(obs::Observable{T}, args...) where T = getindex(timeseries(obs), args...)

"""
    isempty(obs::Observable{T})

Determine wether the observable has not been measurement yet.
"""
Base.isempty(obs::Observable{T}) where T = obs.n_meas == 0