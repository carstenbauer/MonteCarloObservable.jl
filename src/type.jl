mutable struct Observable{T<:Union{AbstractArray, Number}}
    # TODO: What are allowed types of observables? As a group there should be the concept of a mean. So far allow any kind of array and number.

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
    timeseries::Vector{T}
    tsidx::Int # points to next free slot in timeseries (!= n_meas+1 for inmemory == false)

    mean::T # estimate for mean

    outformat::String

    Observable{T}() where T = new()
end

# constructors

"""
    Observable{T}(name::String)

Create an observable of type `T`.
"""
function Observable{T}(name::String; buffersize::Int=100, alloc::Int=1000, inmemory::Bool=true,
                       outfile::String="Observables.jld", dataset::String=name, estimate_error::Bool=false) where T
    obs = Observable{T}()
    obs.name = name
    obs.alloc = alloc
    obs.inmemory = inmemory
    obs.outfile = outfile
    obs.HDF5_dset = dataset

    init!(obs)
    return obs
end

"""
    Observable(T::DataType, name::String)

Create an observable of type `T`.
"""
Observable(T::DataType, posargs...; keyargs...) = Observable{T}(posargs...; keyargs...)

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