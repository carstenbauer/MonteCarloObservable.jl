#=
    # inmemory
    1) saveobs, loadobs: saving a restorable version of the Observable{T} object
    2) exportobs: export results of obs (name, n_meas, time series) to file (Maybe: support (incomplete) import)

    # !inmemory
    1) saveobs, loadobs: same as above
        - how to avoid same grp conflict? if inmemory dump to trg/obsname if !inmemory dump to trg/obsname/observable
    2) exportobs: export results of obs (name, n_meas, time series) to file (Maybe: support (incomplete) import)
        - will have to load everything to memory before dumping.
    3) loadobsmemory
=#

function getindex_fromfile(obs::Observable{T}, idx::Int) where T
    const format = obs.outformat
    const obsname = name(obs)
    const grp = obs.HDF5_dset*"/"

    if format == "jld"
        currmemchunk = ceil(Int, obs.n_meas / obs.alloc)
        chunknr = ceil(Int,idx/obs.alloc)
        chunkidx = mod1(idx, obs.alloc)

        chunknr != currmemchunk || (return obs.timeseries[chunkidx]) # chunk not stored to file yet

        if eltype(T) <: Complex
            # h5read with indices is not supported for compoud data. We could only store as separate _real _imag to make this more efficient.
            return load(obs.outfile, joinpath(grp, "ts_chunk$(chunknr)"))[obs.colons..., chunkidx]
        else # Real
            return squeeze(h5read(obs.outfile, joinpath(grp, "ts_chunk$(chunknr)"), (obs.colons..., chunkidx)), obs.n_dims+1)
        end
    else
        error("Bug: obs.outformat not known in getindex_fromfile! Please file a github issue.")
    end
end

"""
    saveobs(obs::Observable{T}[, filename::AbstractString, entryname::AbstractString])

Saves complete representation of the observable to JLD file.

Default filename is "Observables.jld" and default entryname is `name(obs)`.

See also [`loadobs`](@ref).
"""
function saveobs(obs::Observable{T}, filename::AbstractString=obs.outfile, entryname::AbstractString=(obs.inmemory?obs.HDF5_dset:obs.HDF5_dset*"/observable")) where T
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

"""
    export_results(obs::Observable{T}[, filename::AbstractString, group::AbstractString; timeseries::Bool=false])

Export result for given observable nicely to JLD.

Will export name, number of measurements, estimates for mean and one-sigma error.
Optionally (`timeseries==true`) exports the full time series as well.
"""
function export_result(obs::Observable{T}, filename::AbstractString=obs.outfile, group::AbstractString=obs.HDF5_dset*"_export"; timeseries=false) where T
    const grp = endswith(group, "/")?group:group*"/"

    jldopen(filename, isfile(filename)?"r+":"w") do f
        !HDF5.has(f.plain, grp) || delete!(f, grp)
        write(f, joinpath(grp, "name"), name(obs))
        write(f, joinpath(grp, "count"), length(obs))
        timeseries && write(f, joinpath(grp, "timeseries"), MonteCarloObservable.timeseries(obs))
        write(f, joinpath(grp, "mean"), mean(obs))
        err, conv = error_with_convergence(obs)
        write(f, joinpath(grp, "error"), err)
        write(f, joinpath(grp, "error_conv"), string(conv))
    end
    nothing
end

"""
    export_error(obs::Observable{T}[, filename::AbstractString, group::AbstractString;])

Export one-sigma error estimate and convergence flag.
"""
function export_error(obs::Observable{T}, filename::AbstractString=obs.outfile, group::AbstractString=obs.HDF5_dset) where T
    const grp = endswith(group, "/")?group:group*"/"

    jldopen(filename, isfile(filename)?"r+":"w") do f
        !HDF5.has(f.plain, grp*"error") || delete!(f, grp*"error")
        !HDF5.has(f.plain, grp*"error_conv") || delete!(f, grp*"error_conv")
        err, conv = error_with_convergence(obs)
        write(f, joinpath(grp, "error"), err)
        write(f, joinpath(grp, "error_rel"), err./mean(obs))
        write(f, joinpath(grp, "error_conv"), string(conv))
    end
    nothing
end

"""
    updateondisk(obs::Observable{T}[, filename::AbstractString, group::AbstractString])

This is the crucial function if `inmemory(obs) == false`. It updates the time series on disk.
It is called from `add!` everytime the alloc limit is reached (overflow).
"""
function updateondisk(obs::Observable{T}, filename::AbstractString=obs.outfile, dataset::AbstractString=obs.HDF5_dset) where T
    @assert !obs.inmemory
    @assert obs.tsidx == length(obs.timeseries)+1

    jldopen(filename, isfile(filename)?"r+":"w", compress=true) do f
        updateondisk(obs, f, dataset)
    end
    nothing
end

"""
    updateondisk(obs::Observable{T}, f::JldFile[, group::AbstractString])

updateondisk for JLD
"""
function updateondisk(obs::Observable{T}, f::JLD.JldFile, dataset::AbstractString=obs.HDF5_dset) where T
    @assert !obs.inmemory
    @assert obs.tsidx == length(obs.timeseries)+1

    const obsname = name(obs)
    const grp = dataset*"/"
    const tsgrp = dataset*"/timeseries/"
    const alloc = obs.alloc

    if !HDF5.has(f.plain, grp)
        # initialize
        write(f, joinpath(grp,"count"), length(obs))
        write(f, joinpath(tsgrp,"chunk_count"), 1)
        write(f, joinpath(tsgrp,"ts_chunk1"), obs.timeseries)
        write(f, joinpath(grp, "mean"), mean(obs))

        write(f, joinpath(grp, "name"), name(obs))
        write(f, joinpath(grp, "alloc"), obs.alloc)
        write(f, joinpath(grp, "elsize"), [obs.elsize...])
        write(f, joinpath(grp, "eltype"), string(eltype(obs)))
    else
        try
            cc = read(f, joinpath(tsgrp, "chunk_count"))
            write(f, joinpath(tsgrp,"ts_chunk$(cc+1)"), obs.timeseries)

            delete!(f, joinpath(tsgrp, "chunk_count"))
            write(f, joinpath(tsgrp,"chunk_count"), cc+1)

            c = read(f, joinpath(grp, "count"))
            c+alloc == length(obs) || warn("length(obs) != number of measurements found on disk")
            delete!(f, joinpath(grp, "count"))
            write(f, joinpath(grp,"count"), c+alloc)

            delete!(f, joinpath(grp, "mean"))
            write(f, joinpath(grp, "mean"), mean(obs))
        catch er
            error("Couldn't update on disk! Error: ", er)
        end
    end
    nothing
end


# """
#     writeobs(obs::Observable{T}[, timeseries=false])

# Write estimate for mean and one-sigma error (standard deviation) to file.

# Measurement time series will be dumped as well if `timeseries = true` .
# """
# function writeobs(obs::Observable{T}, filename::AbstractString="Observables.jld" timeseries::Bool=false) where T

# end

JLD.writeas(x::Vector{T}) where T<:AbstractArray = cat(ndims(T)+1, x...)
# JLD.readas()

"""
    loadobs_frommemory(filename::AbstractString, group::AbstractString)

Create an observable based on memory dump (`inmemory==false`).
"""
function loadobs_frommemory(filename::AbstractString, group::AbstractString)
    const grp = endswith(group, "/")?group:group*"/"
    const tsgrp = grp*"timeseries/"

    jldopen(filename) do f
        const name = read(f, joinpath(grp, "name"))
        const alloc = read(f, joinpath(grp, "alloc"))
        const outfile = filename
        const dataset = grp[1:end-1]
        const n_meas = read(f, joinpath(grp, "count"))
        const elsize = Tuple(read(f,joinpath(grp, "elsize")))
        const element_type = read(f, joinpath(grp, "eltype"))
        const themean = read(f,joinpath(grp, "mean"))
        const chunk_count = read(f,joinpath(tsgrp, "chunk_count"))
        const last_ts_chunk = read(f, joinpath(tsgrp, "ts_chunk$(chunk_count)"))

        obs = Observable(eval(parse(element_type)), name; alloc=alloc, outfile=outfile, dataset=dataset, inmemory=false)

        obs.n_meas = n_meas
        obs.elsize = elsize
        obs.mean = themean
        obs.timeseries = [last_ts_chunk[obs.colons...,i] for i in 1:alloc]

        return obs
    end
end

"""
    timeseries_frommemory(filename::AbstractString, group::AbstractString)

Load time series from memory dump (`inmemory==false`) in HDF5/JLD file.

Will load and concatenate time series chunks. Output will be a vector of measurements.
"""
function timeseries_frommemory(filename::AbstractString, group::AbstractString)
    const ts = timeseries_frommemory_flat(filename,group)
    const colons = [Colon() for _ in 1:ndims(ts)-1]
    return [ts[colons..., i] for i in 1:size(ts, ndims(ts))]
end

timeseries_frommemory(obs::Observable{T}) where T = timeseries_frommemory(obs.outfile, obs.HDF5_dset)

"""
    timeseries_frommemory_flat(filename::AbstractString, group::AbstractString)

Load time series from memory dump (`inmemory==false`) in HDF5/JLD file.

Will load and concatenate time series chunks. Output will be higher-dimensional
array whose last dimension corresponds to Monte Carlo time.
"""
function timeseries_frommemory_flat(filename::AbstractString, group::AbstractString)
    const grp = endswith(group, "/")?group:group*"/"
    const tsgrp = grp*"timeseries/"

    jldopen(filename) do f
        const n_meas = read(f, joinpath(grp, "count"))
        const element_type = read(f, joinpath(grp, "eltype"))
        const chunk_count = read(f,joinpath(tsgrp, "chunk_count"))
        const T = eval(parse(element_type))
        const colons = [Colon() for _ in 1:ndims(T)]

        const firstchunk = read(f, joinpath(tsgrp,"ts_chunk1"))
        chunks = Vector{typeof(firstchunk)}(chunk_count)
        chunks[1] = firstchunk

        for c in 2:chunk_count
            chunks[c] = read(f, joinpath(tsgrp,"ts_chunk$(c)"))
        end

        flat_timeseries = cat(ndims(T)+1, chunks...)

        return flat_timeseries
    end
end
