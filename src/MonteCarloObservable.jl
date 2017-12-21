module MonteCarloObservable

    using HDF5

    import Base.push!
    import Base.eltype
    import Base.length
    import Base.getindex
    import Base.endof
    import Base.view
    import Base.isempty
    import Base.mean
    import Base.std
    import Base.clear!
    import Base.ndims
    import Base.size

    import Base.show
    import Base.summary

    include("type.jl")
    include("statistics.jl")
    include("interface.jl")
    include("io.jl")

    export Observable
    # export integrated_autocorrelation_time
    export binning_error
    export jackknife_error

    export add!
    export timeseries
    export reset!
    export clear!
end