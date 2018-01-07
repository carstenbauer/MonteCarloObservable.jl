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

    # trying to find sensible DataType for mean if not given
    mt = meantype
    if mt == Type{Union{}} # not set
        if eltype(t)<:Real
            mt = ndims(t)>0 ? Array{Float64, ndims(t)} : Float64
        else
            mt = ndims(t)>0 ? Array{Complex128, ndims(t)} : Complex128
        end
    end

    @assert ndims(t)==ndims(mt)

    obs = Observable{t, mt}()
    obs.name = name
    obs.alloc = alloc
    obs.inmemory = inmemory
    obs.outfile = outfile
    obs.HDF5_dset = dataset

    init!(obs)
    return obs
end

"""
    init!(obs)

Initialize non-external fields of observable `obs`.
"""
function init!(obs::Observable{T}) where T
    # internal
    obs.n_meas = 0
    obs.elsize = (-1,) # will be determined on first add! call
    obs.colons = [Colon() for _ in 1:ndims(T)]
    obs.n_dims = ndims(T)

    obs.tsidx = 1
    obs.timeseries = Vector{T}(obs.alloc) # init with Missing values in Julia 1.0

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
    end
    nothing
end