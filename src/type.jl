mutable struct Observable{T<:Union{AbstractArray, Number}}
    # TODO: What are allowed types of observables? As a group there should be the concept of a mean. So far allow any kind of array and number.

    # parameters (external)
    name::String
    prealloc::Int
    keep_in_memory::Bool # and maybe dump to HDF5 in the end vs keeping on disk (dumping in chunks)
    outfile::String # format deduced from extension (.h5, .hdf5) (TODO: add .jld, .csv, .bin)
    HDF5_grp::String # where to put data in HDF5 and JLD case

    # internal
    n_meas::Int # total number of measurements
    elsize::Tuple{Vararg{Int}}
    colons::Vector{Colon}
    timeseries::Vector{T}
    tsidx::Int # points to next free slot in timeseries (!= n_meas+1 for keep_in_memory == false)

    mean::T # estimate for mean

    outformat::String

    Observable{T}() where T = new()
end

# constructors

"""
    Observable{T}(name)

Create an observable.
"""
function Observable{T}(name::String; buffersize::Int=100, prealloc::Int=1000, keep_timeseries::Bool=false,
                         keep_in_memory::Bool=true, outfile::String="$(name).h5", group::String=name, estimate_error::Bool=false) where T
    obs = Observable{T}()
    obs.name = name
    obs.prealloc = prealloc
    obs.keep_in_memory = keep_in_memory
    obs.outfile = outfile
    obs.HDF5_grp = endswith(group, "/")?group:group*"/";

    init!(obs)
    return obs
end
Observable(T::DataType, posargs...; keyargs...) = Observable{T}(posargs...; keyargs...)

"""
    init!(obs)

Initialize non-external fields of observable `obs`.
"""
function init!(obs::Observable{T}) where T
    # internal
    obs.n_meas = 0
    obs.elsize = () # will be determined on first add! call
    obs.colons = [Colon() for _ in 1:ndims(T)]

    obs.tsidx = 1
    obs.timeseries = Vector{T}(obs.prealloc) # init with Missing values in Julia 1.0

    zero_arraylike = convert(T, fill(zero(eltype(T)),fill(0, ndims(T))...)) # arraylike means convert(T, array) is possible
    obs.mean = ndims(T) == 0 ? convert(T, zero(eltype(T))) : zero_arraylike

    # figure out outformat
    allowed_ext = ["h5", "hdf5"] # ["h5", "hdf5", "jld", "bin", "csv"]
    try
        ext = lowercase(obs.outfile[end-search(reverse(obs.outfile), '.')+2:end])
        ext in allowed_ext  || error("Unknown outfile extension \"", ext ,"\".")
        obs.outformat = ext
    end
    nothing
end