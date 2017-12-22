#=
Two distinctions:
    1) writing/reading (intermediate) results (readobs, writeobs)
    2) saving a restorable version of the Observable{T} object (saveobs, loadobs)

1) We should support JLD [, HDF5, binary and CSV.]
2) Let's only use JLD here for now.
=#

# TODO!!
function getindex_fromfile(obs::Observable{T}, args...) where T
    const format = obs.outformat

    if format == "h5" || format == "hdf5"
        # if eltype(T) <: Real
            # h5read(obs.outfile, joinpath(obs.grp,obs.name,"timeseries"), (args...))
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
function saveobs(obs::Observable{T}, filename::AbstractString="Observables.jld", entryname::AbstractString=name(obs)) where T
    fileext(filename) == "jld" || error("\"$(filename)\" is not a valid JLD filename.")
    save(filename, entryname, obs)
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
    updateondisk(obs::Observable{T}[, filename::AbstractString, group::AbstractString])

This is the crucial function if `inmemory(obs) == false`. It updates the timeseries on disk.
It is called from `add!` everytime the alloc limit is reached (overflow).
"""
function updateondisk(obs::Observable{T}, filename::AbstractString=obs.outfile, group::AbstractString=obs.HDF5_grp) where T
    @assert !obs.inmemory
    @assert obs.tsidx == length(obs.timeseries)+1

    # TODO from fileext -> open files differently

    jldopen(filename, isfile(filename)?"r+":"w", compress=true) do f
        updateondisk(obs, f, group)
    end
    nothing
end

"""
    updateondisk(obs::Observable{T}, f::JldFile[, group::AbstractString])

updateondisk for JLD
"""
function updateondisk(obs::Observable{T}, f::JLD.JldFile, group::AbstractString=obs.HDF5_grp) where T
    @assert !obs.inmemory
    @assert obs.tsidx == length(obs.timeseries)+1

    const obsname = name(obs)
    const grp = joinpath(group, obsname*"/")
    const alloc = obs.alloc

    if !HDF5.has(f.plain, grp)
        println("innit")
        # initialize
        write(f, joinpath(grp,"count"), length(obs))
        write(f, joinpath(grp,"chunk_count"), 1)
        write(f, joinpath(grp,"ts_chunk1"), obs.timeseries) # TODO JLD.serializer (Array{T} -> T+1dim)
        write(f, joinpath(grp, "mean"), mean(obs))
    else
        println("update")
        try
            cc = read(f, joinpath(grp, "chunk_count"))
            write(f, joinpath(grp,"ts_chunk$(cc+1)"), obs.timeseries) # TODO JLD.serializer (Array{T} -> T+1dim)

            delete!(f, joinpath(grp, "chunk_count"))
            write(f, joinpath(grp,"chunk_count"), cc+1)

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

# Measurement timeseries will be dumped as well if `timeseries = true` .
# """
# function writeobs(obs::Observable{T}, filename::AbstractString="Observables.jld" timeseries::Bool=false) where T

# end