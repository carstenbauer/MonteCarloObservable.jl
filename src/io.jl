#=
Two distinctions:
    1) saving (intermediate) results
    2) saving a restorable version of the Observable{T} object

1) We should support HDF5, JLD, binary and CSV.
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