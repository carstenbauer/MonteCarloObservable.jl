"""
A Markov Chain Monte Carlo observable that doesn't keep track of the standard error.
"""
mutable struct NoErrorObservable{MeasurementType<:SUPPORTED_TYPES, MeanType<:SUPPORTED_TYPES} <: AbstractObservable

    # parameters (external)
    name::String

    # internal
    n_meas::Int # total number of measurements
    elsize::Tuple{Vararg{Int}}
    n_dims::Int

    mean::MeanType # estimate for mean

    NoErrorObservable{T, MT}() where {T, MT} = new()
end




# -------------------------------------------------------------------------
#   Constructor / Initialization
# -------------------------------------------------------------------------
"""
    NoErrorObservable(t, name; keyargs...)

Create an observable of type `t`.

The following keywords are allowed:

* `meantype`: type of the mean (should be compatible with measurement type `t`)
"""
function NoErrorObservable(::Type{T};
                    name::String="unnamed",
                    meantype::DataType=Type{Union{}}) where T

    @assert T <: SUPPORTED_TYPES "Only numbers or arrays of numbers supported as measurement types."
    @assert isconcretetype(T) "Type must be concrete."

    # trying to find sensible DataType for mean if not given
    mt = meantype
    if mt == Type{Union{}} # not set
        if eltype(T)<:Real
            mt = ndims(T)>0 ? Array{Float64, ndims(T)} : Float64
        else
            mt = ndims(T)>0 ? Array{ComplexF64, ndims(T)} : ComplexF64
        end
    end

    @assert ndims(T) == ndims(mt)

    obs = NoErrorObservable{T, mt}()
    obs.name = name

    _init!(obs)
    return obs
end

NoErrorObservable(::Type{T}, name::String; kw...) where T = NoErrorObservable(T; name=name, kw...)




"""
    _init!(obs)

Initialize non-external fields of observable `obs`.
"""
function _init!(obs::NoErrorObservable{T}) where T
    # internal
    obs.n_meas = 0
    obs.elsize = (-1,) # will be determined on first push! call
    obs.n_dims = ndims(T)

    if ndims(T) == 0
        obs.mean = convert(T, zero(eltype(T)))
    else
        obs.mean = convert(T, fill(zero(eltype(T)), fill(0, ndims(T))...))
    end
    nothing
end


"""
    reset!(obs::NoErrorObservable{T})

Resets all measurement information in `obs`.
"""
reset!(obs::NoErrorObservable{T}) where T = _init!(obs)









# -------------------------------------------------------------------------
#   Constructor macros
# -------------------------------------------------------------------------
"""
Convenience macro for generating an Observable from a vector of measurements.
"""
macro noerrorobs(arg)
    return quote
        # local o = Observable($(esc(eltype))($(esc(arg))), $(esc(string(arg))))
        local o = NoErrorObservable($(esc(eltype))($(esc(arg))), "unnamed")
        push!(o, $(esc(arg)))
        o
    end
end







# -------------------------------------------------------------------------
#   Basic properties (mostly adding methods to Base functions)
# -------------------------------------------------------------------------
"""
    eltype(obs::NoErrorObservable{T})

Returns the type `T` of a measurment of the observable.
"""
@inline Base.eltype(obs::NoErrorObservable{T}) where T = T

"""
Length of observable's time series.
"""
@inline Base.length(obs::NoErrorObservable{T}) where T = obs.n_meas

"""
Size of the observable (of one measurement).
"""
@inline Base.size(obs::NoErrorObservable{T}) where T = obs.elsize

"""
Number of dimensions of the observable (of one measurement).

Equivalent to `ndims(T)`.
"""
@inline Base.ndims(obs::NoErrorObservable{T}) where T = ndims(T)

"""
Returns `true` if the observable hasn't been measured yet.
"""
Base.isempty(obs::NoErrorObservable{T}) where T = obs.n_meas == 0

"""
Name of the Observable.
"""
name(obs::NoErrorObservable{T}) where T = obs.name

"""
    rename(obs::NoErrorObservable, name)

Renames the observable.
"""
rename!(obs::NoErrorObservable{T}, name::AbstractString) where T = begin obs.name = name; nothing end

@inline inmemory(obs::NoErrorObservable) = true
@inline isinmemory(obs::NoErrorObservable) = inmemory(obs)






# -------------------------------------------------------------------------
#   Cosmetics: Base.show, Base.summary
# -------------------------------------------------------------------------
function _print_header(io::IO, obs::NoErrorObservable{T}) where T
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
    print(io, "$(sizestr)$(T) NoErrorObservable")
    nothing
end

function _println_body(io::IO, obs::NoErrorObservable{T}) where T
    println("| Name: ", name(obs))
    print("| Measurements: ", length(obs))
    if length(obs) > 0
        if ndims(obs) == 0
            print("\n| Mean: ", round(mean(obs), digits=5))
        end
    end
end


Base.show(io::IO, obs::NoErrorObservable{T,M}) where {T,M} = print(io, "$T NoErrorObservable")

Base.show(io::IO, m::MIME"text/plain", obs::NoErrorObservable{T}) where T = begin
    _print_header(io, obs)
    println(io)
    _println_body(io, obs)
    nothing
end










# -------------------------------------------------------------------------
#   push! and push!
# -------------------------------------------------------------------------
"""
Add measurements to an observable.

    push!(obs::NoErrorObservable{T}, measurement::T; verbose=false)
    push!(obs::NoErrorObservable{T}, measurements::AbstractArray{T}; verbose=false)
"""
function Base.push!(obs::NoErrorObservable) end




# adding single: numbers
Base.push!(obs::NoErrorObservable{T}, measurement::S; kw...) where {T<:Number, S<:Number} = _push!(obs, measurement; kw...);

# adding single: arrays
Base.push!(obs::NoErrorObservable{Array{T,N}}, measurement::AbstractArray{S,N}; kw...) where {T, S<:Number, N} = _push!(obs, measurement; kw...);

# adding multiple: vector of measurements
function Base.push!(obs::NoErrorObservable{T}, measurements::AbstractVector{T}; kw...) where T
    @inbounds for i in eachindex(measurements)
        _push!(obs, measurements[i]; kw...)
    end
    nothing
end

# adding multiple: arrays one dimension higher (last dim == ts dim)
function Base.push!(obs::NoErrorObservable{T}, measurements::AbstractArray{S, N}; kw...) where {T,S<:Number,N}
    N == obs.n_dims + 1 || throw(DimensionMismatch("Dimensions of given measurements ($(N-1)) don't match observable's dimensions ($(obs.n_dims))."))
    length(obs) == 0 || size(measurements)[1:N-1] == obs.elsize || error("Sizes of measurements don't match observable size.")

    @inbounds for i in Base.axes(measurements, ndims(measurements))
        _push!(obs, measurements[.., i]; kw...)
    end
    nothing
end


Base.append!(obs::NoErrorObservable, measurement; kwargs...) = push!(obs, measurement; kwargs...)


# implementation
@inline function _push!(obs::NoErrorObservable{T}, measurement) where T
    if obs.elsize == (-1,) # first add
        obs.elsize = size(measurement)
        obs.mean = zero(measurement)
    end

    size(measurement) == obs.elsize || error("Measurement size != observable size")

    # update mean estimate
    obs.mean = (obs.n_meas * obs.mean + measurement) / (obs.n_meas + 1)
    obs.n_meas += 1
    nothing
end





# -------------------------------------------------------------------------
#   Exporting results
# -------------------------------------------------------------------------
"""
    export_results(obs::NoErrorObservable{T}[, filename::AbstractString, group::AbstractString; timeseries::Bool=false])

Export result for given observable nicely to JLD.

Will export name, number of measurements, and the estimate for the mean.
"""
function export_result(obs::NoErrorObservable{T}, filename::AbstractString, group::AbstractString) where T
    grp = endswith(group, "/") ? group : group*"/"

    jldopen(filename, isfile(filename) ? "r+" : "w") do f
        !HDF5.has(f.plain, grp) || delete!(f, grp)
        write(f, joinpath(grp, "name"), name(obs))
        write(f, joinpath(grp, "count"), length(obs))
        write(f, joinpath(grp, "mean"), mean(obs))
    end
    nothing
end






# -------------------------------------------------------------------------
#   Basic Statistics
# -------------------------------------------------------------------------
"""
Mean of the observable's time series.
"""
Statistics.mean(obs::NoErrorObservable{T}) where T = length(obs) > 0 ? obs.mean : error("Can't calculate mean of empty observable.")