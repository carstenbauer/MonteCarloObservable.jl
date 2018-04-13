module MonteCarloObservable

    using JLD, HDF5
    using StatsBase
    using PyPlot

    import PyPlot.plot

    import Base.push!
    import Base.eltype
    import Base.length
    import Base.getindex
    import Base.endof
    import Base.view
    import Base.isempty
    import Base.mean
    import Base.std
    import Base.var
    import Base.clear!
    import Base.ndims
    import Base.size
    import Base.start
    import Base.next
    import Base.done
    import Base.show
    import Base.summary
    import Base.error
    # import Base.similar
    import Base.==

    include("type.jl")
    include("helpers.jl")
    include("binning.jl")
    include("jackknife.jl")
    include("statistics.jl")
    include("interface.jl")
    include("io.jl")
    include("plotting.jl")

    export Observable
    export @obs

    # statistics
    export tau # autocorrelation time
    export iswithinerrorbars
    export error
    export finderror # experimental
    export isconverged # experimental

    export binning_error
    export jackknife_error

    # interface
    export add!
    export timeseries
    export reset!
    export rename
    export name
    export inmemory

    # io
    export saveobs
    export loadobs
    export export_result
    export loadobs_frommemory
    export timeseries_frommemory
    export timeseries_frommemory_flat

    # plotting
    export plot
    export hist
    export binningplot
    export corrplot

    # overwritten Base
    export clear!
    export mean
    export push!
    export eltype
    export length
    export getindex
    export endof
    export view
    export isempty
    export mean
    export std
    export var
    export clear!
    export ndims
    export size
    export start
    export next
    export done
    export show
    export summary
end
