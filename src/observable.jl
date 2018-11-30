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
    colons::Vector{Colon} # substitute for .. for JLD datasets
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
    obs.timeseries = Vector{T}(undef, obs.alloc) # init with Missing values in Julia 1.0?

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
@inline inmemory(obs::Observable{T}) where T = obs.inmemory

"""
Checks wether the observable is kept in memory (vs. on disk).
"""
@inline isinmemory(obs::Observable) = obs.inmemory

"""
Check if two observables have equal timeseries.
"""
function Base.:(==)(a::Observable, b::Observable)
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
function Base.push!(obs::Observable) end




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
            flush(obs)
            verbose && println("Setting time series index to 1.")
            obs.tsidx = 1
        end
    end
    verbose && println("Done.")
    nothing
end





"""
    flush(obs::Observable)

This is the crucial function if `inmemory(obs) == false`. It updates the time series on disk.
It is called from `add!` everytime the alloc limit is reached (overflow).

You can call the function manually to save an intermediate state.
"""
function Base.flush(obs::Observable)
    @assert !isinmemory(obs) "Can only flush disk observables (`!inmemory(obs)`)."

    fname = obs.outfile
    grp = endswith(obs.HDF5_dset, "/") ? obs.HDF5_dset : obs.HDF5_dset*"/"
    tsgrp = joinpath(grp, "timeseries")
    alloc = obs.alloc

    try
        jldopen(fname, isfile(fname) ? "r+" : "w", compress=true) do f
            if !HDF5.has(f.plain, grp) # first flush?
                write(f, joinpath(grp,"count"), length(obs))
                write(f, joinpath(grp, "mean"), mean(obs))

                write(f, joinpath(grp, "name"), name(obs))
                write(f, joinpath(grp, "alloc"), obs.alloc)
                write(f, joinpath(grp, "elsize"), [obs.elsize...])
                write(f, joinpath(grp, "eltype"), string(eltype(obs)))
                write(f, joinpath(tsgrp,"chunk_count"), 1)
                if obs.tsidx == length(obs.timeseries) + 1 # regular flush
                    # write full chunk
                    write(f, joinpath(tsgrp,"ts_chunk1"), TimeSeriesSerializer(obs.timeseries))
                else # (early) manual flush
                    # write partial chunk
                    hdf5ver = HDF5.libversion
                    hdf5ver >= v"1.10" || @warn "HDF5 version $(hdf5ver) < 1.10.x Manual flushing might lead to larger output file because space won't be freed on dataset delete."
                    write(f, joinpath(tsgrp,"ts_chunk1"), TimeSeriesSerializer(obs.timeseries[1:obs.tsidx-1]))
                end

            else # not first flush
                c = read(f[joinpath(grp, "count")])
                cc = read(f[joinpath(tsgrp, "chunk_count")])

                if !(cc * alloc == c) # was last flushed manually
                    # delete last incomplete chunk
                    delete!(f, joinpath(tsgrp, "ts_chunk$(cc)"))
                    cc -= 1
                end

                if obs.tsidx == length(obs.timeseries) + 1 # regular flush
                    # write full chunk
                    write(f, joinpath(tsgrp,"ts_chunk$(cc+1)"), TimeSeriesSerializer(obs.timeseries))
                else # (early) manual flush
                    # write partial chunk
                    hdf5ver = HDF5.libversion
                    hdf5ver >= v"1.10" || @warn "HDF5 version $(hdf5ver) < 1.10.x Manual flushing might lead to larger output file because space won't be freed on dataset delete."
                    write(f, joinpath(tsgrp,"ts_chunk$(cc+1)"), TimeSeriesSerializer(obs.timeseries[1:obs.tsidx-1]))
                end

                delete!(f, joinpath(tsgrp, "chunk_count"))
                write(f, joinpath(tsgrp,"chunk_count"), cc+1)

                delete!(f, joinpath(grp, "count"))
                write(f, joinpath(grp,"count"), length(obs))

                delete!(f, joinpath(grp, "mean"))
                write(f, joinpath(grp, "mean"), mean(obs))
            end
        end
    catch er
        error("Couldn't update observable on disk! Error: ", er)
    end
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




function Base.getindex(obs::Observable{T}, idx::Int) where T
    1 <= idx <= length(obs) || throw(BoundsError(typeof(obs), idx))
    if obs.inmemory
        return getindex(obs.timeseries, idx)
    else
        if length(obs) < obs.alloc # no chunk dumped to disk yet
            return obs.timeseries[idx]
        else
            return getindex_fromfile(obs, idx)
        end
    end
end
function Base.getindex(obs::Observable{T}, rng::UnitRange{Int}) where T
    rng.start >= 1 && rng.stop <= length(obs) || throw(BoundsError(typeof(obs), rng))
    if obs.inmemory
        return getindex(obs.timeseries, rng)
    else
        if length(obs) < obs.alloc # no chunk dumped to disk yet
            return obs.timeseries[rng]
        else
            return getindexrange_fromfile(obs, rng)
        end
    end
end
Base.getindex(obs::Observable, c::Colon) = getindex(obs, 1:length(obs))




# disk observables: get from file
function getindex_fromfile(obs::Observable{T}, idx::Int)::T where T
    tsgrp = joinpath(obs.HDF5_dset, "timeseries/")

    currmemchunk = ceil(Int, obs.n_meas / obs.alloc)
    chunknr = ceil(Int,idx / obs.alloc)
    idx_in_chunk = mod1(idx, obs.alloc)

    chunknr != currmemchunk || (return obs.timeseries[idx_in_chunk]) # chunk not stored to file yet
    
    return _getindex_ts_chunk(obs, chunknr, idx_in_chunk)
end


function getindexrange_fromfile(obs::Observable{T}, rng::UnitRange{Int})::Vector{T} where T

    getchunknr = i -> fld1(i, obs.alloc)
    chunknr_start = getchunknr(rng.start)
    chunknr_stop = getchunknr(rng.stop)
    
    chunkidx_first_start = mod1(rng.start, obs.alloc)
    chunkidx_first_stop = chunknr_start * obs.alloc
    chunkidx_last_start = 1
    chunkidx_last_stop = mod1(rng.stop, obs.alloc)

    if chunknr_start == chunknr_stop # all in one chunk
        startidx = mod1(rng.start, obs.alloc)
        stopidx = mod1(rng.stop, obs.alloc)
        return _getindex_ts_chunk(obs, chunknr_start, startidx:stopidx)
    else
        # fallback: load full time series and extract range
        return vcat(timeseries_frommemory(obs), obs.timeseries[1:obs.tsidx-1])[rng]

        # While the following is cheaper on memory, it is much(!) slower. TODO: bring it up to speed
        # v = Vector{T}(undef, length(rng))
        # i = 1 # pointer to first free slot in v
        # @indbounds for c in chunknr_start:chunknr_stop
        #     if c == chunknr_start
        #         r = chunkidx_first_start:chunkidx_first_stop

        #         _getindex_ts_chunk!(v[1:length(r)], obs, c, r)
        #         i += length(r)

        #     elseif c == chunknr_stop
        #         r = chunkidx_last_start:chunkidx_last_stop
        #         _getindex_ts_chunk!(v[i:lastindex(v)], obs, c, r)
        #     else
        #         _getindex_ts_chunk!(v[i:(i+obs.alloc-1)], obs, c, Colon())
        #         i += obs.alloc
        #     end
        # end

        # return v

    end
end



function _getindex_ts_chunk(obs::Observable{T}, chunknr::Int, idx_in_chunk::Int)::T where T
    tsgrp = joinpath(obs.HDF5_dset, "timeseries/")

    # Use hyperslab to only read the requested element from disk
    return jldopen(obs.outfile, "r") do f
        val = f[joinpath(tsgrp, "ts_chunk$(chunknr)")][obs.colons..., idx_in_chunk]
        res = dropdims(val, dims=obs.n_dims+1)
        return ndims(T) == 0 ? res[1] : res
    end
end

function _getindex_ts_chunk(obs::Observable{T}, chunknr::Int, rng::UnitRange{Int})::Vector{T} where T
    tsgrp = joinpath(obs.HDF5_dset, "timeseries/")

    # Use hyperslab to only read the requested elements from disk
    return jldopen(obs.outfile, "r") do f
        val = f[joinpath(tsgrp, "ts_chunk$(chunknr)")][obs.colons..., rng]
        return [val[.., i] for i in 1:size(val, ndims(val))]
    end
end

function _getindex_ts_chunk(obs::Observable{T}, chunknr::Int, c::Colon)::Vector{T} where T
    _getindex_ts_chunk(obs, chunknr, 1:obs.alloc)
end




# function _getindex_ts_chunk!(out::AbstractVector{T}, obs::Observable{T}, chunknr::Int, rng::UnitRange{Int})::Nothing where T
#     @assert length(out) == length(rng)
#     tsgrp = joinpath(obs.HDF5_dset, "timeseries/")

#     # Use hyperslab to only read the requested elements from disk
#     jldopen(obs.outfile, "r") do f
#         val = f[joinpath(tsgrp, "ts_chunk$(chunknr)")][obs.colons..., rng]
#         # return [val[.., i] for i in 1:size(val, ndims(val))]

#         for i in 1:size(val, ndims(val))
#             out[i] = val[.., i]
#         end
#     end
#     nothing
# end

# function _getindex_ts_chunk!(out::AbstractVector{T}, obs::Observable{T}, chunknr::Int, c::Colon)::Nothing where T
#     _getindex_ts_chunk!(out, obs, chunknr, 1:obs.alloc)
#     nothing
# end




















# -------------------------------------------------------------------------
#   Saving and loading of (complete) observable
# -------------------------------------------------------------------------
"""
    saveobs(obs::Observable{T}[, filename::AbstractString, entryname::AbstractString])

Saves complete representation of the observable to JLD file.

Default filename is "Observables.jld" and default entryname is `name(obs)`.

See also [`loadobs`](@ref).
"""
function saveobs(obs::Observable{T}, filename::AbstractString=obs.outfile, 
                    entryname::AbstractString=(obs.inmemory ? obs.HDF5_dset : obs.HDF5_dset*"/observable")) where T
    fileext(filename) == "jld" || error("\"$(filename)\" is not a valid JLD filename.")
    if !isfile(filename)
        save(filename, entryname, obs)
    else
        jldopen(filename, "r+") do f
            !HDF5.has(f.plain, entryname) || delete!(f, entryname)
            write(f, entryname, obs)
        end
    end
    nothing
end



"""
    loadobs(filename::AbstractString, entryname::AbstractString)

Load complete representation of an observable from JLD file.

See also [`saveobs`](@ref).
"""
function loadobs(filename::AbstractString, entryname::AbstractString)
    fileext(filename) == "jld" || error("\"$(filename)\" is not a valid JLD filename.")
    return load(filename, entryname)
end

















# -------------------------------------------------------------------------
#   Exporting results
# -------------------------------------------------------------------------
"""
    export_results(obs::Observable{T}[, filename::AbstractString, group::AbstractString; timeseries::Bool=false])

Export result for given observable nicely to JLD.

Will export name, number of measurements, estimates for mean and one-sigma error.
Optionally (`timeseries==true`) exports the full time series as well.
"""
function export_result(obs::Observable{T}, filename::AbstractString=obs.outfile, group::AbstractString=obs.HDF5_dset*"_export"; timeseries=false, error=true) where T
    grp = endswith(group, "/") ? group : group*"/"

    jldopen(filename, isfile(filename) ? "r+" : "w") do f
        !HDF5.has(f.plain, grp) || delete!(f, grp)
        write(f, joinpath(grp, "name"), name(obs))
        write(f, joinpath(grp, "count"), length(obs))
        timeseries && write(f, joinpath(grp, "timeseries"), TimeSeriesSerializer(MonteCarloObservable.timeseries(obs)))
        write(f, joinpath(grp, "mean"), mean(obs))
        if error
            err, conv = error_with_convergence(obs)
            write(f, joinpath(grp, "error"), err)
            write(f, joinpath(grp, "error_rel"), abs.(err./mean(obs)))
            write(f, joinpath(grp, "error_conv"), string(conv))
        end
    end
    nothing
end



"""
    export_error(obs::Observable{T}[, filename::AbstractString, group::AbstractString;])

Export one-sigma error estimate and convergence flag.
"""
function export_error(obs::Observable{T}, filename::AbstractString=obs.outfile, group::AbstractString=obs.HDF5_dset) where T
    grp = endswith(group, "/") ? group : group*"/"

    jldopen(filename, isfile(filename) ? "r+" : "w") do f
        !HDF5.has(f.plain, grp*"error") || delete!(f, grp*"error")
        !HDF5.has(f.plain, grp*"error_rel") || delete!(f, grp*"error_rel")
        !HDF5.has(f.plain, grp*"error_conv") || delete!(f, grp*"error_conv")
        err, conv = error_with_convergence(obs)
        write(f, joinpath(grp, "error"), err)
        write(f, joinpath(grp, "error_rel"), abs.(err./mean(obs)))
        write(f, joinpath(grp, "error_conv"), string(conv))
    end
    nothing
end









# -------------------------------------------------------------------------
#   load things from memory dump
# -------------------------------------------------------------------------
"""
    loadobs_frommemory(filename::AbstractString, group::AbstractString)

Create an observable based on a memory dump (`inmemory==false`).
"""
function loadobs_frommemory(filename::AbstractString, group::AbstractString)
    grp = endswith(group, "/") ? group : group*"/"
    tsgrp = joinpath(grp, "timeseries")

    isfile(filename) || error("File not found.")

    jldopen(filename) do f
        HDF5.has(f.plain, grp) || error("Group not found in file.")
        name = read(f, joinpath(grp, "name"))
        alloc = read(f, joinpath(grp, "alloc"))
        outfile = filename
        dataset = grp[1:end-1]
        c = read(f, joinpath(grp, "count"))
        elsize = Tuple(read(f,joinpath(grp, "elsize")))
        element_type = read(f, joinpath(grp, "eltype"))
        themean = read(f,joinpath(grp, "mean"))
        cc = read(f,joinpath(tsgrp, "chunk_count"))
        last_ts_chunk = read(f, joinpath(tsgrp, "ts_chunk$(cc)"))

        T = jltype(element_type)
        MT = typeof(themean)
        obs = Observable{T, MT}()

        obs.name = name
        obs.alloc = alloc
        obs.inmemory = false
        obs.outfile = outfile
        obs.HDF5_dset = dataset
        _init!(obs)

        obs.n_meas = c
        obs.elsize = elsize
        obs.mean = themean

        for i in axes(last_ts_chunk, ndims(last_ts_chunk))
            obs.timeseries[i] = last_ts_chunk[..,i]
        end

        if !(cc * alloc == c) # was last flushed manually
            obs.tsidx = size(last_ts_chunk, ndims(last_ts_chunk)) + 1
        end

        return obs
    end
end




mean_frommemory(filename::AbstractString, group::AbstractString) = _frommemory(filename, group, "mean")
error_frommemory(filename::AbstractString, group::AbstractString) = _frommemory(filename, group, "error")
function _frommemory(filename::AbstractString, group::AbstractString, field::AbstractString)
    grp = endswith(group, "/") ? group : group*"/"
    d = joinpath(grp, field)
    return jldopen(filename) do f
        return read(f[d])
    end
end




# time series
timeseries(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory(filename, group; kw...)
ts(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory(filename, group; kw...)
"""
    timeseries_frommemory(filename::AbstractString, group::AbstractString)

Load time series from memory dump (`inmemory==false`) in HDF5/JLD file.

Will load and concatenate time series chunks. Output will be a vector of measurements.
"""
function timeseries_frommemory(filename::AbstractString, group::AbstractString; kw...)
    ts = timeseries_frommemory_flat(filename, group; kw...)
    r = [ts[.., i] for i in 1:size(ts, ndims(ts))]
    return r
end
timeseries_frommemory(obs::Observable{T}; kw...) where T = timeseries_frommemory(obs.outfile, obs.HDF5_dset; kw...)





timeseries_flat(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory_flat(filename, group; kw...)
ts_flat(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory_flat(filename, group; kw...)
"""
    timeseries_frommemory_flat(filename::AbstractString, group::AbstractString)

Load time series from memory dump (`inmemory==false`) in HDF5/JLD file.

Will load and concatenate time series chunks. Output will be higher-dimensional
array whose last dimension corresponds to Monte Carlo time.
"""
function timeseries_frommemory_flat(filename::AbstractString, group::AbstractString; verbose=false)
    grp = endswith(group, "/") ? group : group*"/"
    tsgrp = joinpath(grp, "timeseries")

    isfile(filename) || error("File not found.")
    jldopen(filename) do f
        HDF5.has(f.plain, grp) || error("Group not found in file.")
        if typeof(f[grp]) == JLD.JldGroup && HDF5.has(f.plain, tsgrp) && typeof(f[tsgrp]) == JLD.JldGroup
            # n_meas = read(f, joinpath(grp, "count"))
            element_type = read(f, joinpath(grp, "eltype"))
            chunk_count = read(f,joinpath(tsgrp, "chunk_count"))
            T = jltype(element_type)

            firstchunk = read(f, joinpath(tsgrp,"ts_chunk1"))
            chunks = Vector{typeof(firstchunk)}(undef, chunk_count)
            chunks[1] = firstchunk

            for c in 2:chunk_count
                chunks[c] = read(f, joinpath(tsgrp,"ts_chunk$(c)"))
            end

            flat_timeseries = cat(chunks..., dims=ndims(T)+1)

            return flat_timeseries

        else
            if typeof(f[grp]) == JLD.JldDataset
                return read(f, grp)
            elseif HDF5.has(f.plain, joinpath(grp, "timeseries"))
                verbose && println("Loading time series (export_result or old format).")
                flat_timeseries = read(f, joinpath(grp, "timeseries"))
                return flat_timeseries

            elseif HDF5.has(f.plain, joinpath(grp, "timeseries_real"))
                verbose && println("Loading complex time series (old format).")
                flat_timeseries = read(f, joinpath(grp, "timeseries_real")) + im*read(f, joinpath(grp, "timeseries_imag"))
                return flat_timeseries

            else
                error("No timeseries/observable found.")
            end
        end
    end
end






# personal wrapper
function getfrom(filename::AbstractString, obs::AbstractString, what::AbstractString)
    if !(what in ["ts", "ts_flat", "timeseries", "timeseries_flat"])
        d = joinpath("obs/", obs, what)
        return jldopen(filename) do f
            return read(f[d])
        end
    else
        grp = joinpath("obs/", obs)
        return occursin("flat", what) ? ts_flat(filename, grp) : ts(filename, grp)
    end
end





"""
List all observables in a given file and HDF5 group.
"""
function listobs(filename::AbstractString, group::AbstractString="obs/")
    s = Vector{String}()
    HDF5.h5open(filename, "r") do f
        if HDF5.has(f, group)
            for el in HDF5.names(f[group])
                # println(el)
                push!(s, el)
            end
        end
    end
    return s
end




"""
Remove an observable.
"""
function rmobs(filename::AbstractString, dset::AbstractString, group::AbstractString="obs/")
    HDF5.h5open(filename, "r+") do f
        HDF5.o_delete(f, joinpath(group,dset))
    end
end








# -------------------------------------------------------------------------
#   Basic Statistics
# -------------------------------------------------------------------------
"""
Mean of the observable's time series.
"""
Statistics.mean(obs::Observable{T}) where T = length(obs) > 0 ? obs.mean : error("Can't calculate mean of empty observable.")

"""
Standard deviation of the observable's time series (assuming uncorrelated data).

See also [`mean(obs)`](@ref), [`var(obs)`](@ref), and [`error(obs)`](@ref).
"""
Statistics.std(obs::Observable{T}) where T = length(obs) > 0 ? std(timeseries(obs)) : error("Can't calculate std of empty observable.")

"""
Variance of the observable's time series (assuming uncorrelated data).

See also [`mean(obs)`](@ref), [`std(obs)`](@ref), and [`error(obs)`](@ref).
"""
Statistics.var(obs::Observable{T}) where T = length(obs) > 0 ? var(timeseries(obs)) : error("Can't calculate variance of empty observable.")







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
Base.error(obs::Observable) = binning_error(timeseries(obs))
Base.error(obs::Observable, binsize::Int) = binning_error(timeseries(obs), binsize)

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