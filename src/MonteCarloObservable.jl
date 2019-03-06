"""
A package for handling observables in a Markov Chain Monte Carlo simulation.

See http://github.com/crstnbr/MonteCarloObservable.jl for more information.
"""
module MonteCarloObservable

    using Statistics
    using JLD, EllipsisNotation, BinningAnalysis, Lazy
    import HDF5

    abstract type AbstractObservable end

    include("helpers.jl")
    include("shared.jl")
    include("observable.jl")
    include("lightobservable.jl")

    include("binning.jl")

    # Jackknife
    include("Jackknife.jl")
    export Jackknife

    # general
    export Observable, DiskObservable, LightObservable
    export @obs, @diskobs

    # statistics
    export tau, iswithinerrorbars
    export error, error_naive, error_with_convergence, std_error
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
    export flush
    export ObservableResult, load_result

    # plotting
    # export plot, hist, binningplot, errorplot, corrplot
end
