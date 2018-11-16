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

    import Base: push!, eltype, length, getindex, view, isempty, ndims, size, iterate, summary, error
    import Base.==
    import Statistics: mean, std, var
    import Distributed: clear!

    include("type.jl")
    include("helpers.jl")
    include("binning.jl")
    include("jackknife.jl")
    include("statistics.jl")
    include("interface.jl")
    include("io.jl")
    include("plotting.jl")

    export Observable
    export @obs, @diskobs

    # statistics
    export tau, iswithinerrorbars
    export error, error_naive, error_with_convergence
    export binning_error, jackknife_error
    # export isconverged # experimental
    export mean, var, std

    # interface
    export add!, push!, reset!, clear!
    export timeseries, ts
    export rename, name
    export inmemory, length, eltype, getindex, view, isempty, ndims, size, iterate

    # io
    export saveobs, loadobs, listobs, rmobs
    export export_result, export_error
    export loadobs_frommemory
    export timeseries_frommemory, timeseries_frommemory_flat
    export timeseries_flat, ts_flat

    # plotting
    export plot, hist, binningplot, errorplot, corrplot
end
