module MonteCarloObservable

    using JLD, HDF5
    using StatsBase
    using ErrorAnalysis
    using PyPlot

    import PyPlot.plot

    import ErrorAnalysis.binning_error
    import ErrorAnalysis.jackknife_error
    import ErrorAnalysis.iswithinerrorbars
    import ErrorAnalysis.plot_error
    import ErrorAnalysis.plot_binning_R

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
    # import Base.similar
    import Base.==

    include("type.jl")
    include("helpers.jl")
    include("statistics.jl")
    include("interface.jl")
    include("io.jl")
    include("plotting.jl")

    export Observable

    # statistics
    # export integrated_autocorrelation_time
    export binning_error
    export jackknife_error
    export iswithinerrorbars

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
    # export plot_timeseries # === plot(obs)
    export plot
    # export plot_histogram # === hist(obs)
    export hist
    # export plot_binning # === binningplot(obs)
    export binningplot
    # export plot_autocorrelation # === corrplot(obs)
    export corrplot
    # export plot_error
    # export plot_binning_R

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
