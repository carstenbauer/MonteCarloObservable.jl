# -------------------------------------------------------------------------
#   Saving and loading of (complete) observable
# -------------------------------------------------------------------------
"""
    saveobs(obs::Observable{T}[, filename::AbstractString, entryname::AbstractString])

Saves complete representation of the observable to JLD file.

Default filename is "Observables.jld" and default entryname is `name(obs)`.

See also [`loadobs`](@ref).
"""
function saveobs(obs::AbstractObservable, filename::AbstractString=obs.outfile, 
                    entryname::AbstractString=(inmemory(obs) ? obs.group : obs.group*"/observable"))
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