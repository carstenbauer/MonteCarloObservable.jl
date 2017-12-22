#=
Two distinctions:
    1) writing/reading (intermediate) results (readobs, writeobs)
    2) saving a restorable version of the Observable{T} object (saveobs, loadobs)

1) We should support HDF5 [, JLD, binary and CSV.]
2) Let's only use JLD here for now.
=#

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
    extension(filename) == "jld" || error("\"$(filename)\" is not a valid JLD filename.")
    save(filename, entryname, obs)
    nothing
end

"""
    loadobs(obs::Observable{T})

Load complete representation of an observable from JLD file.

See also [`saveobs`](@ref).
"""
function loadobs(filename::AbstractString, entryname::AbstractString)
    extension(filename) == "jld" || error("\"$(filename)\" is not a valid JLD filename.")
    return load(filename, entryname)
end