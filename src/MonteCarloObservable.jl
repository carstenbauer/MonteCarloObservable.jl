module MonteCarloObservable

    using JLD, HDF5
    using StatsBase
    using EllipsisNotation

    # stdlibs
    using Statistics

    try
        using PyPlot
        import PyPlot.plot
    catch
    end

    import Base.push!
    import Base.eltype
    import Base.length
    import Base.getindex
    import Base.endof
    import Base.view
    import Base.isempty
    import Statistics: mean, std, var
    import Distributed: clear!
    import Base.ndims
    import Base.size
    import Base.iterate
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
    export @diskobs

    # statistics
    export tau # autocorrelation time
    export iswithinerrorbars
    export error
    export error_naive
    export error_with_convergence
    # export isconverged # experimental

    export binning_error
    export jackknife_error

    # interface
    export add!
    export timeseries
    export ts # === timeseries
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
    export timeseries_flat
    # export timeseries
    export ts_flat
    # export ts

    export listobs
    export rmobs

    # plotting
    export plot
    export hist
    export binningplot
    export errorplot
    export corrplot
end
