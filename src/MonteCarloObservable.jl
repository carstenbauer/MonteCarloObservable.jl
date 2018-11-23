"""
A package for handling observables in a Markov Chain Monte Carlo simulation.

See http://github.com/crstnbr/MonteCarloObservable.jl for more information.
"""
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

    include("helpers.jl")
    include("observable.jl")

    include("binning.jl")
    include("jackknife.jl")
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
    export add!, push!, reset!
    export timeseries, ts
    export rename, name
    export inmemory, isinmemory, length, eltype, getindex, view, isempty, ndims, size, iterate

    # io
    export saveobs, loadobs, listobs, rmobs
    export export_result, export_error
    export loadobs_frommemory
    export timeseries_frommemory, timeseries_frommemory_flat, mean_frommemory, error_frommemory
    export timeseries_flat, ts_flat
    export getfrom

    # plotting
    export plot, hist, binningplot, errorplot, corrplot
end
