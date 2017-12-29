var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Description-1",
    "page": "Home",
    "title": "Description",
    "category": "section",
    "text": "This package provides an implementation of an Observable in a Markov Chain Monte Carlo simulation context (like MonteCarlo.jl).During a Markov chain Monte Carlo simulation a Markov walker (after thermalization) walks through configuration space according to the equilibrium distribution. Typically, one measures observables along the Markov path, records the results, and in the end averages the measurements. MonteCarloObservable.jl provides all the necessary tools for conveniently conducting these types of measurements, including automatic error estimation of the averages and export to file."
},

{
    "location": "index.html#Authors-1",
    "page": "Home",
    "title": "Authors",
    "category": "section",
    "text": "Carsten Bauer (web, github)"
},

{
    "location": "manual/gettingstarted.html#",
    "page": "Getting started",
    "title": "Getting started",
    "category": "page",
    "text": ""
},

{
    "location": "manual/gettingstarted.html#Manual-1",
    "page": "Getting started",
    "title": "Manual",
    "category": "section",
    "text": ""
},

{
    "location": "manual/gettingstarted.html#Installation-/-Updating-1",
    "page": "Getting started",
    "title": "Installation / Updating",
    "category": "section",
    "text": "To install the package execute the following command in the REPL:Pkg.clone(\"https://github.com/crstnbr/MonteCarloObservable.jl\")To obtain the latest version of the package just do Pkg.update() or specifically Pkg.update(\"MonteCarloObservable\")."
},

{
    "location": "manual/gettingstarted.html#Example-1",
    "page": "Getting started",
    "title": "Example",
    "category": "section",
    "text": "This is a simple demontration of how to use the package for measuring a floating point observable:using MonteCarloObservable\nobs = Observable(Float64, \"myobservable\")\nadd!(obs, 1.23) # add measurement\nobs\npush!(obs, rand(10)) # same as add!\nlength(obs)\nmean(obs)\nstd(obs) # one-sigma error of mean (binning analysis)\ntimeseries(obs)\nobs[3] # conventional element accessing\nobs[end-2:end]\nsaveobs(obs, \"myobservable.jld\")"
},

{
    "location": "manual/errorestimation.html#",
    "page": "Error estimation",
    "title": "Error estimation",
    "category": "page",
    "text": ""
},

{
    "location": "manual/errorestimation.html#Error-estimation-1",
    "page": "Error estimation",
    "title": "Error estimation",
    "category": "section",
    "text": ""
},

{
    "location": "manual/errorestimation.html#Binning-analysis-1",
    "page": "Error estimation",
    "title": "Binning analysis",
    "category": "section",
    "text": "TODO"
},

{
    "location": "manual/errorestimation.html#Resources-1",
    "page": "Error estimation",
    "title": "Resources",
    "category": "section",
    "text": "J. Gubernatis, N. Kawashima, and P. Werner, Quantum Monte Carlo Methods: Algorithms for Lattice Models, Book (2016)V. Ambegaokar, and M. Troyer, Estimating errors reliably in Monte Carlo simulations of the Ehrenfest model, American Journal of Physics 78, 150 (2010)"
},

{
    "location": "manual/memdisk.html#",
    "page": "Memory / disk storage",
    "title": "Memory / disk storage",
    "category": "page",
    "text": ""
},

{
    "location": "manual/memdisk.html#Memory-/-disk-storage-1",
    "page": "Memory / disk storage",
    "title": "Memory / disk storage",
    "category": "section",
    "text": "TODO"
},

{
    "location": "methods/general.html#",
    "page": "General",
    "title": "General",
    "category": "page",
    "text": ""
},

{
    "location": "methods/general.html#Methods:-General-1",
    "page": "General",
    "title": "Methods: General",
    "category": "section",
    "text": "Below you find all general exports."
},

{
    "location": "methods/general.html#Index-1",
    "page": "General",
    "title": "Index",
    "category": "section",
    "text": "Pages = [\"general.md\"]"
},

{
    "location": "methods/general.html#MonteCarloObservable.Observable-Union{Tuple{String}, Tuple{T}} where T",
    "page": "General",
    "title": "MonteCarloObservable.Observable",
    "category": "Method",
    "text": "Observable{T}(name)\n\nCreate an observable.\n\n\n\n"
},

{
    "location": "methods/general.html#Base.Distributed.clear!-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "General",
    "title": "Base.Distributed.clear!",
    "category": "Method",
    "text": "clear!(obs::Observable{T})\n\nClears all measurement information in obs. Identical to init! and reset!.\n\n\n\n"
},

{
    "location": "methods/general.html#Base.eltype-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "General",
    "title": "Base.eltype",
    "category": "Method",
    "text": "eltype(obs::Observable{T})\n\nReturns the type T of a measurment of the observable.\n\n\n\n"
},

{
    "location": "methods/general.html#Base.getindex-Union{Tuple{MonteCarloObservable.Observable{T},Vararg{Any,N} where N}, Tuple{T}} where T",
    "page": "General",
    "title": "Base.getindex",
    "category": "Method",
    "text": "getindex(obs::Observable{T}, args...)\n\nGet an element of the measurement timeseries of the observable.\n\n\n\n"
},

{
    "location": "methods/general.html#Base.isempty-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "General",
    "title": "Base.isempty",
    "category": "Method",
    "text": "isempty(obs::Observable{T})\n\nDetermine wether the observable hasn't been measured yet.\n\n\n\n"
},

{
    "location": "methods/general.html#Base.length-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "General",
    "title": "Base.length",
    "category": "Method",
    "text": "length(obs::Observable{T})\n\nNumber of measurements of the observable.\n\n\n\n"
},

{
    "location": "methods/general.html#Base.ndims-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "General",
    "title": "Base.ndims",
    "category": "Method",
    "text": "ndims(obs::Observable{T})\n\nNumber of dimensions of the observable (of one measurement).\n\nEquivalent to ndims(T).\n\n\n\n"
},

{
    "location": "methods/general.html#Base.push!-Union{Tuple{MonteCarloObservable.Observable{T},AbstractArray{T,N} where N}, Tuple{T}} where T",
    "page": "General",
    "title": "Base.push!",
    "category": "Method",
    "text": "push!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false)\n\nAdd multiple measurements to observable obs. Note that because of preallocation this isn't really a push.\n\n\n\n"
},

{
    "location": "methods/general.html#Base.push!-Union{Tuple{MonteCarloObservable.Observable{T},T}, Tuple{T}} where T",
    "page": "General",
    "title": "Base.push!",
    "category": "Method",
    "text": "push!(obs::Observable{T}, measurement::T; verbose=false)\n\nAdd a measurement to observable obs. Note that because of preallocation this isn't really a push.\n\n\n\n"
},

{
    "location": "methods/general.html#Base.size-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "General",
    "title": "Base.size",
    "category": "Method",
    "text": "size(obs::Observable{T})\n\nSize of the observable (of one measurement).\n\n\n\n"
},

{
    "location": "methods/general.html#Base.view-Union{Tuple{MonteCarloObservable.Observable{T},Vararg{Any,N} where N}, Tuple{T}} where T",
    "page": "General",
    "title": "Base.view",
    "category": "Method",
    "text": "view(obs::Observable{T}, args...)\n\nGet a view into the measurement timeseries of the observable.\n\n\n\n"
},

{
    "location": "methods/general.html#MonteCarloObservable.add!-Union{Tuple{MonteCarloObservable.Observable{T},AbstractArray{T,N} where N}, Tuple{T}} where T",
    "page": "General",
    "title": "MonteCarloObservable.add!",
    "category": "Method",
    "text": "add!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false)\n\nAdd multiple measurements to observable obs.\n\n\n\n"
},

{
    "location": "methods/general.html#MonteCarloObservable.add!-Union{Tuple{MonteCarloObservable.Observable{T},T}, Tuple{T}} where T",
    "page": "General",
    "title": "MonteCarloObservable.add!",
    "category": "Method",
    "text": "add!(obs::Observable{T}, measurement::T; verbose=false)\n\nAdd a measurement to observable obs.\n\n\n\n"
},

{
    "location": "methods/general.html#MonteCarloObservable.inmemory-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "General",
    "title": "MonteCarloObservable.inmemory",
    "category": "Method",
    "text": "inmemory(obs::Observable{T})\n\nChecks wether the observable is kept in memory (vs. on disk).\n\n\n\n"
},

{
    "location": "methods/general.html#MonteCarloObservable.name-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "General",
    "title": "MonteCarloObservable.name",
    "category": "Method",
    "text": "name(obs::Observable{T})\n\nReturns the name of the observable.\n\n\n\n"
},

{
    "location": "methods/general.html#MonteCarloObservable.rename-Union{Tuple{MonteCarloObservable.Observable{T},AbstractString}, Tuple{T}} where T",
    "page": "General",
    "title": "MonteCarloObservable.rename",
    "category": "Method",
    "text": "rename(obs::Observable{T}, name)\n\nRenames the observable.\n\n\n\n"
},

{
    "location": "methods/general.html#MonteCarloObservable.reset!-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "General",
    "title": "MonteCarloObservable.reset!",
    "category": "Method",
    "text": "reset!(obs::Observable{T})\n\nResets all measurement information in obs. Identical to init! and clear!.\n\n\n\n"
},

{
    "location": "methods/general.html#MonteCarloObservable.timeseries-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "General",
    "title": "MonteCarloObservable.timeseries",
    "category": "Method",
    "text": "timeseries(obs::Observable{T})\n\nReturns the measurement timeseries of an observable.\n\nIf inmemory(obs) == false it will read the timeseries from disk and thus might take some time.\n\nSee also getindex and view.\n\n\n\n"
},

{
    "location": "methods/general.html#Documentation-1",
    "page": "General",
    "title": "Documentation",
    "category": "section",
    "text": "Modules = [MonteCarloObservable]\nPrivate = false\nOrder   = [:function, :type]\nPages = [\"type.jl\", \"interface.jl\"]"
},

{
    "location": "methods/statistics.html#",
    "page": "Statistics",
    "title": "Statistics",
    "category": "page",
    "text": ""
},

{
    "location": "methods/statistics.html#Methods:-Statistics-1",
    "page": "Statistics",
    "title": "Methods: Statistics",
    "category": "section",
    "text": "Below you find all statistics related exports."
},

{
    "location": "methods/statistics.html#Index-1",
    "page": "Statistics",
    "title": "Index",
    "category": "section",
    "text": "Pages = [\"statistics.md\"]"
},

{
    "location": "methods/statistics.html#Base.mean-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Statistics",
    "title": "Base.mean",
    "category": "Method",
    "text": "mean(obs::Observable{T})\n\nEstimate of the mean of the observable.\n\n\n\n"
},

{
    "location": "methods/statistics.html#Base.std-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Statistics",
    "title": "Base.std",
    "category": "Method",
    "text": "std(obs::Observable{T})\n\nEstimate of the standard deviation (one-sigma error) of the mean. Respects correlations between measurements through binning analysis.\n\nNote that this is not the same as Base.std(timeseries(obs)), not even  for uncorrelated measurements.\n\nCorresponds to the square root of var(obs). See also mean(obs).\n\n\n\n"
},

{
    "location": "methods/statistics.html#Base.var-Union{Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "Statistics",
    "title": "Base.var",
    "category": "Method",
    "text": "var(obs::Observable{T})\n\nEstimate of the variance of the mean. Respects correlations between measurements through binning analysis.\n\nNote that this is not the same as Base.var(timeseries(obs)), not even  for uncorrelated measurements.\n\nCorresponds to the square of std(obs). See also mean(obs).\n\n\n\n"
},

{
    "location": "methods/statistics.html#Documentation-1",
    "page": "Statistics",
    "title": "Documentation",
    "category": "section",
    "text": "Modules = [MonteCarloObservable, ErrorAnalysis]\nPrivate = false\nOrder   = [:function]\nPages = [\"statistics.jl\"]"
},

{
    "location": "methods/io.html#",
    "page": "IO",
    "title": "IO",
    "category": "page",
    "text": ""
},

{
    "location": "methods/io.html#Methods:-IO-1",
    "page": "IO",
    "title": "Methods: IO",
    "category": "section",
    "text": "Below you find all IO related exports."
},

{
    "location": "methods/io.html#Index-1",
    "page": "IO",
    "title": "Index",
    "category": "section",
    "text": "Pages = [\"io.md\"]"
},

{
    "location": "methods/io.html#MonteCarloObservable.export_result-Union{Tuple{MonteCarloObservable.Observable{T},AbstractString,AbstractString}, Tuple{MonteCarloObservable.Observable{T},AbstractString}, Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "IO",
    "title": "MonteCarloObservable.export_result",
    "category": "Method",
    "text": "export_results(obs::Observable{T}[, filename::AbstractString, entryname::AbstractString; timeseries::Bool=false])\n\nExport result for given observable nicely to JLD.\n\nWill export name, number of measurements, estimates for mean and one-sigma error (standard deviation). Optionally (timeseries==true) exports the full timeseries as well.\n\n\n\n"
},

{
    "location": "methods/io.html#MonteCarloObservable.loadobs-Tuple{AbstractString,AbstractString}",
    "page": "IO",
    "title": "MonteCarloObservable.loadobs",
    "category": "Method",
    "text": "loadobs(filename::AbstractString, entryname::AbstractString)\n\nLoad complete representation of an observable from JLD file.\n\nSee also saveobs.\n\n\n\n"
},

{
    "location": "methods/io.html#MonteCarloObservable.loadobs_frommemory-Tuple{AbstractString,AbstractString}",
    "page": "IO",
    "title": "MonteCarloObservable.loadobs_frommemory",
    "category": "Method",
    "text": "loadobs_frommemory(filename::AbstractString, group::AbstractString)\n\nCreate an observable based on memory dump (inmemory==false).\n\n\n\n"
},

{
    "location": "methods/io.html#MonteCarloObservable.saveobs-Union{Tuple{MonteCarloObservable.Observable{T},AbstractString,AbstractString}, Tuple{MonteCarloObservable.Observable{T},AbstractString}, Tuple{MonteCarloObservable.Observable{T}}, Tuple{T}} where T",
    "page": "IO",
    "title": "MonteCarloObservable.saveobs",
    "category": "Method",
    "text": "saveobs(obs::Observable{T}[, filename::AbstractString, entryname::AbstractString])\n\nSaves complete representation of the observable to JLD file.\n\nDefault filename is \"Observables.jld\" and default entryname is name(obs).\n\nSee also loadobs.\n\n\n\n"
},

{
    "location": "methods/io.html#MonteCarloObservable.timeseries_frommemory-Tuple{AbstractString,AbstractString}",
    "page": "IO",
    "title": "MonteCarloObservable.timeseries_frommemory",
    "category": "Method",
    "text": "timeseries_frommemory(filename::AbstractString, group::AbstractString)\n\nLoad timeseries from memory dump (inmemory==false) in HDF5/JLD file.\n\nWill load and concatenate timeseries chunks. Output will be a vector of measurements.\n\n\n\n"
},

{
    "location": "methods/io.html#MonteCarloObservable.timeseries_frommemory_flat-Tuple{AbstractString,AbstractString}",
    "page": "IO",
    "title": "MonteCarloObservable.timeseries_frommemory_flat",
    "category": "Method",
    "text": "timeseries_frommemory_flat(filename::AbstractString, group::AbstractString)\n\nLoad timeseries from memory dump (inmemory==false) in HDF5/JLD file.\n\nWill load and concatenate timeseries chunks. Output will be higher-dimensional array whose last dimension corresponds to Monte Carlo time.\n\n\n\n"
},

{
    "location": "methods/io.html#Documentation-1",
    "page": "IO",
    "title": "Documentation",
    "category": "section",
    "text": "Modules = [MonteCarloObservable]\nPrivate = false\nOrder   = [:function]\nPages = [\"io.jl\"]"
},

]}
